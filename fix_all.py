# -*- coding: utf-8 -*-
"""Fix bottom_nav.dart - P1-11: Change icons + FAB color fix"""
import os

path = r'C:\OpenFaith-Flutter\openfaith_app\lib\navigation\bottom_nav.dart'
with open(path, 'r', encoding='utf-8-sig') as f:
    content = f.read()

# Change explore to book icon for Learn tab
content = content.replace(
    "_buildNavItem(1, Icons.explore_outlined, Icons.explore, '\u5b66\u4e60')",
    "_buildNavItem(1, Icons.menu_book_outlined, Icons.menu_book, '\u5b66\u4e60')"
)

# Change notifications to chat icon for Messages tab
content = content.replace(
    "_buildNavItem(2, Icons.notifications_outlined, Icons.notifications, '\u6d88\u606f'",
    "_buildNavItem(2, Icons.chat_bubble_outline, Icons.chat_bubble, '\u6d88\u606f'"
)

# Fix FAB inner circle color from #0A0E1F to #050816
content = content.replace('color: Color(0xFF0A0E1F)', 'color: Color(0xFF050816)')

with open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)

print('bottom_nav.dart updated successfully')
