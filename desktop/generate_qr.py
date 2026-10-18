import sys
from pathlib import Path
from config import ServerConfig
from qr_pairing import QRPairingManager

def main():
    config = ServerConfig.load()
    mgr = QRPairingManager(config.host, config.port)
    
    qr_png = Path("C:/Projects/desktop/pairing_qr.png")
    mgr.save_qr_image(str(qr_png))
    
    print("\n==================================================")
    print("           DevPad QR Pairing Generator             ")
    print("==================================================")
    print(f"Host: {mgr.get_detectable_lan_ip()}:{config.port}")
    print(f"Device Identity: {mgr.device_name}")
    print(f"High-res QR Code Image generated at:\n  {qr_png}")
    print("==================================================\n")
    print(mgr.generate_qr_ascii())
    print("\n[Tip] Open DevPad on your Android phone and scan this QR code.")
    print("Scan from the Home screen QR button or in Settings > Scan Workstation QR.\n")

if __name__ == "__main__":
    main()
