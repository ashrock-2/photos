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
OUTPUT_DIR="$PROJECT_ROOT/gallery"

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

# 출력 디렉토리 생성
mkdir -p "$OUTPUT_DIR"

# CSS 파일 복사
cp "$PROJECT_ROOT/style.css" "$OUTPUT_DIR/"

# 날짜별로 이미지 그룹화
declare -A date_files
for image in "$PHOTO_DIR"/*.JPG; do
    [ -f "$image" ] || continue
    date=$(exiftool -DateTimeOriginal -s -s -s "$image" | cut -d' ' -f1 | tr ':' '-')
    date_files[$date]+="$image "
done

# 메인 인덱스 HTML 시작
cat "$TEMPLATE_DIR/header.html" > "$PROJECT_ROOT/index.html"
echo "<ul class='date-list'>" >> "$PROJECT_ROOT/index.html"

# 날짜를 정렬하여 처리
for date in $(echo ${(k)date_files} | tr ' ' '\n' | sort -r); do
    output_file="$OUTPUT_DIR/$date.html"
    
    # 날짜별 HTML 생성
    cat "$TEMPLATE_DIR/header.html" > "$output_file"
    echo "<h2>$date</h2>" >> "$output_file"
    
    # 인덱스 페이지에 링크 추가
    echo "<li><a href='gallery/$date.html'>$date</a></li>" >> "$PROJECT_ROOT/index.html"
    
    # 해당 날짜의 이미지들 처리
    for image in ${=date_files[$date]}; do
        absolute_path=$(realpath "$image")
        relative_path=${absolute_path#$PROJECT_ROOT/}
        
        # EXIF 데이터 추출
        datetime=$(exiftool -DateTimeOriginal -s -s -s "$image")
        camera_model=$(exiftool -Model -s -s -s "$image")
        lens_info=$(exiftool -LensModel -s -s -s "$image")
        focal_length=$(exiftool -FocalLength -s -s -s "$image")
        fnumber=$(exiftool -FNumber -s -s -s "$image")
        iso=$(exiftool -ISO -s -s -s "$image")
        exposure=$(exiftool -ExposureTime -s -s -s "$image")
        
        # GPS 정보 처리
        lat=$(exiftool -GPSLatitude -s -s -s "$image")
        lon=$(exiftool -GPSLongitude -s -s -s "$image")
        alt=$(exiftool -GPSAltitude -s -s -s "$image")
        
        if [ ! -z "$lat" ] && [ ! -z "$lon" ]; then
            gps_position="$lat, $lon"
            gps_maps_link="https://maps.google.com/?q=$lat,$lon"
            gps_altitude="$alt meters"
        else
            gps_position="No data"
            gps_maps_link=""
            gps_altitude="No data"
        fi
        
        # 템플릿에 데이터 적용
        sed -e "s|{{image_path}}|../$relative_path|g" \
            -e "s|{{datetime}}|$datetime|g" \
            -e "s|{{camera_model}}|$camera_model|g" \
            -e "s|{{lens_info}}|$lens_info|g" \
            -e "s|{{focal_length}}|$focal_length|g" \
            -e "s|{{fnumber}}|$fnumber|g" \
            -e "s|{{iso}}|$iso|g" \
            -e "s|{{exposure}}|$exposure|g" \
            -e "s|{{gps_position}}|$gps_position|g" \
            -e "s|{{gps_altitude}}|$gps_altitude|g" \
            "$TEMPLATE_DIR/photo-item.html" >> "$output_file"
    done
    
    # 푸터 추가
    cat "$TEMPLATE_DIR/footer.html" >> "$output_file"
done

# 메인 인덱스 HTML 완성
echo "</ul>" >> "$PROJECT_ROOT/index.html"
cat "$TEMPLATE_DIR/footer.html" >> "$PROJECT_ROOT/index.html"

echo "갤러리가 생성되었습니다!" 