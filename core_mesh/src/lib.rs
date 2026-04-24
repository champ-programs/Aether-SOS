pub mod protocol;
pub mod routing;
pub mod crypto;

pub use protocol::{AetherPacket, SosLevel};
pub use routing::*;
pub use crypto::*;

use std::os::raw::{c_char, c_int, c_uchar};
use std::slice;
use std::ptr;

/// Aether 預設固定金鑰 (實務上應從安全儲存區讀取)
const STATIC_KEY: [u8; 32] = [42; 32]; 

/// C-ABI 導出：解密 Payload
/// 返回值需在 Dart 端釋放，或透過約定長度處理。這裡為簡化，返回固定長度或由調用方傳入 buffer。
#[no_mangle]
pub extern "C" fn aether_decrypt(
    encrypted_data: *const c_uchar,
    len: c_int,
    out_buffer: *mut c_uchar,
    out_len: *mut c_int,
) -> c_int {
    if encrypted_data.is_null() || out_buffer.is_null() || out_len.is_null() {
        return -1; // Null pointer error
    }

    let data_slice = unsafe { slice::from_raw_parts(encrypted_data, len as usize) };
    let crypto = AetherCrypto::new(&STATIC_KEY);
    
    match crypto.decrypt_payload(data_slice) {
        Ok(decrypted) => {
            unsafe {
                if (decrypted.len() as c_int) > *out_len {
                    return -2; // Buffer too small
                }
                ptr::copy_nonoverlapping(decrypted.as_ptr(), out_buffer, decrypted.len());
                *out_len = decrypted.len() as c_int;
            }
            0 // Success
        }
        Err(_) => -3, // Decryption failed
    }
}
