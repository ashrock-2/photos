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

# HTML 시작 부분 생성
cat > "$PROJECT_ROOT/index.html" << EOL
<head>
  <title>ashrock-photos</title>
  <link rel="stylesheet" type="text/css" href="style.css" />
  <link rel="icon" type="image/svg+xml" href="favicon.ico" />
</head>

<body>
  <main>
EOL

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
    
    # HTML에 이미지와 메타데이터 추가
    cat >> "$PROJECT_ROOT/index.html" << EOL
    <div>
      <img src="$relative_path" />
      <div class="metadata">
        <p>촬영 시간: $datetime</p>
        <p>조리개: f/$fnumber</p>
        <p>ISO: $iso</p>
        <p>셔터 스피드: $exposure</p>
      </div>
    </div>
EOL
done

# HTML 마무리
cat >> "$PROJECT_ROOT/index.html" << EOL
  </main>
</body>
EOL

echo "갤러리가 생성되었습니다!" 