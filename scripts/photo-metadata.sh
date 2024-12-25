#!/bin/zsh

# 필요한 도구 확인
if ! command -v exiftool &> /dev/null; then
    echo "exiftool이 설치되어 있지 않습니다. 먼저 설치해주세요."
    echo "brew install exiftool 또는 apt-get install libimage-exiftool-perl"
    exit 1
fi

# 현재 디렉토리의 모든 JPG 파일 처리
for image in *.JPG; do
    # 파일이 존재하는지 확인
    [ -f "$image" ] || continue
    
    echo "\n=== $image 파일의 메타데이터 ==="
    exiftool -DateTimeOriginal \
            -FNumber \
            -ISO \
            -ExposureTime \
            -GPSLatitude \
            -GPSLongitude \
            "$image" | \
    while IFS=: read -r key value; do
        # 결과 포맷팅
        printf "%-20s : %s\n" "${key## }" "${value## }"
    done
done 