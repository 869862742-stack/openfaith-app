import os
base = r"C:\OpenFaith-Flutter\lib\screens\learn"
print("Starting file write process...")
print(f"Target: {base}")
print(f"Exists: {os.path.exists(base)}")
print(f"Current files: {os.listdir(base)}")
# Step 1: Write book_detail_screen.dart
print("Step 1: Writing book_detail_screen.dart...")
path1 = os.path.join(base, "book_detail_screen.dart")
print(f"Target path: {path1}")
print("Ready to receive content...")
