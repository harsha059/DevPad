import sys
import tkinter as tk
from pathlib import Path
from PIL import Image, ImageTk
import qrcode
from config import ServerConfig
from qr_pairing import QRPairingManager

def show_fresh_qr():
    config = ServerConfig.load()
    mgr = QRPairingManager(config.host, config.port, ttl_seconds=86400)
    
    payload = mgr.generate_payload()
    import json
    qr_str = json.dumps(payload)
    
    # Generate PIL image in memory
    qr = qrcode.QRCode(
        version=1,
        box_size=10,
        border=3,
    )
    qr.add_data(qr_str)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    
    qr_png = Path("C:/Projects/desktop/pairing_qr.png")
    try:
        img.save(str(qr_png))
    except Exception:
        pass

    root = tk.Tk()
    root.title("DevPad Workstation Pairing")
    root.geometry("440x540")
    root.configure(bg="#0B1017")
    root.attributes("-topmost", True)
    
    tk.Label(
        root,
        text="DevPad QR Pairing",
        font=("Segoe UI", 16, "bold"),
        fg="#36E1BD",
        bg="#0B1017",
        pady=10
    ).pack()
    
    tk.Label(
        root,
        text=f"Host: {payload['host']}:{config.port}\nDevice: {payload['device_name']}",
        font=("Segoe UI", 11),
        fg="#E2E8F0",
        bg="#0B1017"
    ).pack(pady=2)

    pil_img = img.resize((300, 300), Image.Resampling.NEAREST)
    qr_tk_img = ImageTk.PhotoImage(pil_img)
    
    img_label = tk.Label(root, image=qr_tk_img, bg="#FFFFFF", padx=10, pady=10)
    img_label.image = qr_tk_img
    img_label.pack(pady=10)

    tk.Label(
        root,
        text="Point your phone camera at this QR code.\nTap 'Confirm & Save' on your phone.",
        font=("Segoe UI", 9),
        fg="#94A3B8",
        bg="#0B1017",
        pady=2
    ).pack()

    tk.Button(
        root,
        text="Close Window",
        command=root.destroy,
        bg="#36E1BD",
        fg="#0B1017",
        font=("Segoe UI", 10, "bold"),
        padx=20,
        pady=6,
        relief="flat"
    ).pack(pady=8)

    root.mainloop()

if __name__ == "__main__":
    show_fresh_qr()
