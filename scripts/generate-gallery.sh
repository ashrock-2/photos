#!/bin/zsh

# 사용법 체크
if [ $# -ne 1 ]; then
    echo "사용법: $0 <사진_디렉토리_경로>"
    echo "예시: $0 ../photos"
    exit 1
fi

PHOTO_DIR="$1"
SCRIPT_DIR="$(dirname "$0")"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/..")"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

# 디렉토리 존재 확인
if [ ! -d "$PHOTO_DIR" ]; then
    echo "에러: '$PHOTO_DIR' 디렉토리를 찾을 수 없습니다."
    exit 1
fi

# exiftool 확인
if ! command -v exiftool &> /dev/null; then
    echo "exiftool이 설치되어 있지 않습니다."
    exit 1
fi

# HTML 헤더 복사
cat "$TEMPLATE_DIR/header.html" > "$PROJECT_ROOT/index.html"

# 지정된 디렉토리의 모든 JPG 파일 처리
for image in "$PHOTO_DIR"/*.JPG; do
    [ -f "$image" ] || continue
    
    # 상대 경로 계산 (프로젝트 루트 기준)
    absolute_path=$(realpath "$image")
    relative_path=${absolute_path#$PROJECT_ROOT/}
    
    # EXIF 데이터 추출
    datetime=$(exiftool -DateTimeOriginal -s -s -s "$image")
    fnumber=$(exiftool -FNumber -s -s -s "$image")
    iso=$(exiftool -ISO -s -s -s "$image")
    exposure=$(exiftool -ExposureTime -s -s -s "$image")
    
    # 템플릿 파일 읽고 변수 치환
    sed -e "s|{{image_path}}|$relative_path|g" \
        -e "s|{{datetime}}|$datetime|g" \
        -e "s|{{fnumber}}|$fnumber|g" \
        -e "s|{{iso}}|$iso|g" \
        -e "s|{{exposure}}|$exposure|g" \
        "$TEMPLATE_DIR/photo-item.html" >> "$PROJECT_ROOT/index.html"
done

cat "$TEMPLATE_DIR/footer.html" >> "$PROJECT_ROOT/index.html"

echo "갤러리가 생성되었습니다!" 