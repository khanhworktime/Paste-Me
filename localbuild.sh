#!/bin/bash

# --- CẤU HÌNH DỰ ÁN ---
APP_NAME="PasteMe"       # Tên App của bạn
SCHEME_NAME="PasteMe"    # Tên Scheme (thường giống tên App)
BUILD_DIR="./LocalBuild"    # Thư mục chứa file build

# Màu sắc cho log đẹp hơn
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Bắt đầu quy trình Build Local cho ${APP_NAME}...${NC}"

# 1. Dọn dẹp thư mục build cũ
echo -e "\n${YELLOW}[1/4] 🧹 Đang dọn dẹp file rác...${NC}"
rm -rf "$BUILD_DIR"
xcodebuild clean -scheme "$SCHEME_NAME" -destination 'platform=macOS' -quiet

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Lỗi Clean dự án! Kiểm tra lại Xcode.${NC}"
    exit 1
fi

# 2. Thực hiện Build (Release Mode)
echo -e "\n${YELLOW}[2/4] 🔨 Đang biên dịch (Compiling)...${NC}"
# Lưu ý: -quiet để ẩn bớt log rác, bỏ đi nếu muốn xem chi tiết
xcodebuild build \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$BUILD_DIR" \
  -quiet

# Kiểm tra kết quả build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build THẤT BẠI. Vui lòng kiểm tra lỗi code trong Xcode.${NC}"
    exit 1
fi

# Đường dẫn đến file .app thành phẩm
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"

# 3. Kiểm tra file tồn tại
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ Không tìm thấy file .app tại: $APP_PATH${NC}"
    exit 1
fi

# 4. Xử lý quyền (Gatekeeper Bypass)
echo -e "\n${YELLOW}[3/4] 🔓 Đang xử lý quyền bảo mật (xattr)...${NC}"
xattr -cr "$APP_PATH"

echo -e "\n${GREEN}✅ BUILD THÀNH CÔNG!${NC}"
echo -e "📂 File App nằm tại: ${GREEN}$APP_PATH${NC}"

# 5. Mở thư mục chứa App
echo -e "\n${YELLOW}[4/4] 📂 Đang mở Finder...${NC}"
open "$BUILD_DIR/Build/Products/Release"

# (Tuỳ chọn) Chạy thử App luôn
# echo "🚀 Đang chạy thử App..."
# open "$APP_PATH"