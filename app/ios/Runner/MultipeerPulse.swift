import Foundation
import Network

/// Aether iOS Pulse - 使用 Network Framework (Bonjour TXT Records) 模擬 NAN SDI 廣播
/// 由於 Apple 鎖定底層 Wi-Fi Aware，我們透過 NWListener 與 NWBrowser 的 TXT 記錄
/// 來實現「無連線背景資料廣播」，極限負載約可達 1300 Bytes，足以容納 256 Bytes 封包。
@available(iOS 14.0, *)
class MultipeerPulse {
    private let serviceType = "_aether._tcp"
    private var listener: NWListener?
    private var browser: NWBrowser?
    
    /// 開始脈衝：將 AetherPacket 壓入 TXT Record 進行背景廣播
    func startPulse(encryptedPayload: Data) {
        guard encryptedPayload.count <= 256 else {
            print("Payload exceeds 256 bytes.")
            return
        }
        
        startAdvertising(payload: encryptedPayload)
        startListening()
    }
    
    /// 將封包變成 Bonjour 廣播的 TXT 記錄
    private func startAdvertising(payload: Data) {
        do {
            // 使用隨機 Port 即可，因為我們不打算建立真正的 TCP 連線
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters)
            
            // 核心魔法：將資料直接寫入 TXT Record，不需握手即可被周圍設備掃描到
            let txtRecord = NWConnection.ContentContext(
                identifier: "AetherPulse",
                expiration: 0,
                priority: 1.0,
                isFinal: false,
                antecedent: nil,
                metadata: [NWProtocolTXT.Metadata([
                    "payload": payload
                ])]
            )
            
            listener?.service = NWListener.Service(name: "AetherNode", type: serviceType, txtRecord: txtRecord.metadata?.first?.txtDictionary)
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Aether iOS Pulse (Advertiser) is active.")
                case .failed(let error):
                    print("Advertiser failed: \(error)")
                default:
                    break
                }
            }
            
            listener?.start(queue: .global(qos: .background))
            
        } catch {
            print("Failed to start NWListener: \(error)")
        }
    }
    
    /// 監聽周圍的 Bonjour TXT 記錄
    private func startListening() {
        let parameters = NWParameters.tcp
        browser = NWBrowser(for: .bonjour(type: serviceType, domain: "local."), using: parameters)
        
        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            for result in results {
                if case let .bonjour(txtRecord) = result.metadata {
                    if let payloadData = txtRecord.dictionary["payload"] {
                        print("Received Aether Pulse via iOS AWDL! Size: \(payloadData.count) bytes")
                        
                        // TODO: 透過 FFI 傳遞給 Rust 核心 `routing.rs`
                        // handleIncomingPacketFromApple(payloadData)
                    }
                }
            }
        }
        
        browser?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Aether iOS Listener is scanning...")
            case .failed(let error):
                print("Scanner failed: \(error)")
            default:
                break
            }
        }
        
        browser?.start(queue: .global(qos: .background))
    }
    
    func stopPulse() {
        listener?.cancel()
        browser?.cancel()
    }
}
