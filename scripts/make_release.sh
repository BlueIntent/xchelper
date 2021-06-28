# OUTPUT_DIR=$(mktemp -d -t xchelper-release)

ROOT_PATH=`pwd`
BUILD_PATH=$ROOT_PATH/build
RELEASE_PATH=$BUILD_PATH/release
PRODUCTS_PATH=${ROOT_PATH}/build/products

VERSION=`sh ${ROOT_PATH}/xchelper.sh --version | awk -F ' ' {'print $3'}`
CODE_ZIP_NAME=xchelper-$VERSION
CODE_ZIP_PATH=$RELEASE_PATH/$CODE_ZIP_NAME
BIN_ZIP_NAME=xchelper-v$VERSION
BIN_ZIP_PATH=$RELEASE_PATH/$BIN_ZIP_NAME

rm -rf $BUILD_PATH
mkdir -p $PRODUCTS_PATH

# bin zip
mkdir -p $BIN_ZIP_PATH
cp -P xchelper.sh $BIN_ZIP_PATH/xchelper
chmod 777 $BIN_ZIP_PATH/xchelper
cd ${RELEASE_PATH} && zip -r -q $PRODUCTS_PATH/$BIN_ZIP_NAME.zip $BIN_ZIP_NAME && cd $ROOT_PATH

# code zip 
rsync -r ./ $CODE_ZIP_PATH --exclude build --exclude .git
cd ${RELEASE_PATH} && zip -r -q $PRODUCTS_PATH/$CODE_ZIP_NAME.zip $CODE_ZIP_NAME && cd $ROOT_PATH
cd ${RELEASE_PATH} && tar -czf $PRODUCTS_PATH/$CODE_ZIP_NAME.tar.gz $CODE_ZIP_NAME && cd $ROOT_PATH

echo output: ${BUILD_PATH}