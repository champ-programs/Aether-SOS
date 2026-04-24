use chrono::Utc;
use serde::{Deserialize, Serialize};

/// 救援等級 (SOS Level)
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum SosLevel {
    /// 尋找網路/節點，非緊急 (Pulse)
    Discover = 0,
    /// 受困但無生命危險
    Trapped = 1,
    /// 受傷，需要醫療支援
    Injured = 2,
    /// 命懸一線 (Critical)
    Critical = 3,
}

/// AetherMesh/1.0 輕量化封包結構
/// 在 Mesh 網路中廣播，為了防冗餘，使用 message_id 進行追蹤
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AetherPacket {
    /// 唯一封包 ID (UUID v4 縮寫或雜湊) - 用於 Mesh 防冗餘
    pub message_id: String,
    /// 發送者的 Aether ID (通常是公鑰的 Hash)
    pub sender_id: String,
    /// UTC 時間戳，用於過期檢查與排序
    pub timestamp: i64,
    /// Geo-Hash 位置資訊 (例如 "ws0e9")
    pub geo_hash: String,
    /// 救援等級
    pub sos_level: SosLevel,
    /// 使用 ChaCha20-Poly1305 加密的 Payload (包含具體求救訊息、生理數值等)
    pub encrypted_payload: Vec<u8>,
    /// Time-to-Live (跳數控制) - 預防無限迴圈，初始為 7
    pub ttl: u8,
    /// 上一個轉發此訊息的節點 ID
    pub last_forwarder: String,
}

impl AetherPacket {
    /// 建立新的 Aether 封包
    pub fn new(
        sender_id: String,
        geo_hash: String,
        sos_level: SosLevel,
        encrypted_payload: Vec<u8>,
    ) -> Self {
        let timestamp = Utc::now().timestamp_millis();
        let message_id = format!("{}-{}", sender_id, timestamp); // 簡單的 ID 生成
        
        Self {
            message_id,
            sender_id,
            timestamp,
            geo_hash,
            sos_level,
            encrypted_payload,
            ttl: 7, // 預設 TTL 為 7
            last_forwarder: sender_id.clone(),
        }
    }

    /// 驗證封包是否過期 (例如大於 24 小時)
    pub fn is_expired(&self) -> bool {
        let now = Utc::now().timestamp_millis();
        (now - self.timestamp) > 24 * 60 * 60 * 1000 // 24 hours
    }
}
