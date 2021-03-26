#!/bin/bash
# 资源文件路径
RESOURCE_DIR=temp/resource.txt
# 目标文件路径
TARGET_DIR=./target/bb.txt
# 临时数据表
TEMP_DIR=./target/temp.txt
# 最终结果-建表语句
RESULT_CREATE_DIR=./target/result_create.txt
# 最终结果-查询语句
RESULT_SELECT_DIR=./target/result_select.txt


# 清空文件历史数据
echo "开始清空历史数据。。。"
true > $TARGET_DIR
true > $TEMP_DIR
true > $RESULT_CREATE_DIR
true > $RESULT_SELECT_DIR
echo "完成清空历史数据。。。"

# 设置标准输入输出
note() {
    printf "$*\n" 1>&2;
}
warning() {
    printf "warning: $*\n" 1>&2;
}
error() {
    printf "error: $*\n" 1>&2;
    exit 1
}

# 读取文件
operate() {
  local file=$1
  # Oracle中需要转换成Doris中Varchar的类型
  local oracleToVarchar="VARCHAR、VARCHAR2、NCLOB、CLOB"
  # Oracle中需要转换成Doris中INT的类型
  local oracleToINT="NUMBER、INTEGER、INT"
  # Oracle中需要转换成Doris中CHAR的类型
  local oracleToCHAR="CHAR、NCHAR"
  # Oracle中需要转换成Doris中CHAR的类型
  local oracleToDATE="DATE"
  for line in `cat $file`
  do
#    echo $line
    # 是字符串“VARCHAR、VARCHAR2、NCLOB、CLOB”替换为VARCHAR
    if [[ $oracleToVarchar =~ $line ]]; then
      echo "VARCHAR(" >> $TARGET_DIR
    elif [[ $oracleToINT =~ $line ]]; then
      echo "INT(" >> $TARGET_DIR
    elif [[ $oracleToCHAR =~ $line ]]; then
      echo "CHAR(" >> $TARGET_DIR
    elif [[ $oracleToDATE =~ $line ]]; then
      echo "DATE-数据类型之后需要删除(" >> $TARGET_DIR
    else
      echo $line >> $TARGET_DIR
    fi

  done
}

# 3行合为一行
compose(){
  local file=$1
  sed 'N;N;s/\n/ /g' $file >> $RESULT_CREATE_DIR
}

# 文件行尾处理
addLineEnd(){
  local file=$1
  echo "****************"
  sed "s/$/&),/g" $file >> $TEMP_DIR
  true > $file
  cp $TEMP_DIR $file
}

# 替换所有空格
replaceAllBlank(){
  true > $TEMP_DIR
  local file=$1
  echo "********开始替换所有空格********"
  sed s/[[:space:]]//g $file >> $TEMP_DIR
  true > $file
  cp $TEMP_DIR $file
  echo "********完成替换所有空格********"
}

# Doris数据类型前添加空格
addDataTypeBlank(){
  local file=$1
  # Doris中数据类型
  # 由于该算法根据字符串匹配，Doris中数据类型有字符串包含的关系；暂不支持CHAR、DATETIME、LARGEINT、SMALLINT、TINYINT类型
  local dorisDataTypeArr=(BIGINT BITMAP BOOLEAN CHAR DATE DATETIME DECIMAL DOUBLE FLOAT HLL INT LARGEINT SMALLINT TINYINT VARCHAR)
  echo "********开始数据类型前添加空格********"
  for(( i=0;i<${#dorisDataTypeArr[@]};i++))
  do
    #${#array[@]}获取数组长度用于循环
    local dataType=${dorisDataTypeArr[i]}

    if [[ "BIGINT" == "$dataType" ]]; then
      true > $TEMP_DIR
      sed "s/BIGINT/ BIGINT/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file
    elif [[ "BITMAP" == "$dataType" ]]; then
      true > $TEMP_DIR
      sed "s/BITMAP/ BITMAP/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file
    elif [[ "BOOLEAN" == "$dataType" ]]; then
      true > $TEMP_DIR
      sed "s/BOOLEAN/ BOOLEAN/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file
#    elif [[ "CHAR" == "$dataType" ]]; then
#      true > $TEMP_DIR
#      sed "s/CHAR/ CHAR/g" $file >> $TEMP_DIR
#      true > $file
#      cp $TEMP_DIR $file
    elif [[ "DATE" == "$dataType" ]]; then
      true > $TEMP_DIR
      sed "s/DATE/ DATE/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file
#    elif [[ "DATETIME" == "$dataType" ]]; then
#      true > $TEMP_DIR
#      sed "s/DATETIME/ DATETIME/g" $file >> $TEMP_DIR
#      true > $file
#      cp $TEMP_DIR $file
    elif [[ "DECIMAL" == "$dataType" ]]; then
      true > $TEMP_DIR
      sed "s/DECIMAL/ DECIMAL/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file
    elif [[ "DOUBLE" == "$dataType" ]]; then
      true > $TEMP_DIR
      sed "s/DOUBLE/ DOUBLE/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file
    elif [[ "FLOAT" == "$dataType" ]]; then
      true > $TEMP_DIR
      sed "s/FLOAT/ FLOAT/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file
    elif [[ "HLL" == "$dataType" ]]; then
      true > $TEMP_DIR
      sed "s/HLL/ HLL/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file
    elif [[ "INT" == "$dataType" ]]; then
      true > $TEMP_DIR
      sed "s/INT/ INT/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file

      # 由于Oracle数据中NUMBER类型默认长度为0，此处需要特殊处理
      true > $TEMP_DIR
      sed "s/(0)/(11)/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file

#    elif [[ "LARGEINT" == "$dataType" ]]; then
#      true > $TEMP_DIR
#      sed "s/LARGEINT/ LARGEINT/g" $file >> $TEMP_DIR
#      true > $file
#      cp $TEMP_DIR $file
#    elif [[ "SMALLINT" == "$dataType" ]]; then
#      true > $TEMP_DIR
#      sed "s/SMALLINT/ SMALLINT/g" $file >> $TEMP_DIR
#      true > $file
#      cp $TEMP_DIR $file
#    elif [[ "TINYINT" == "$dataType" ]]; then
#      true > $TEMP_DIR
#      sed "s/TINYINT/ TINYINT/g" $file >> $TEMP_DIR
#      true > $file
#      cp $TEMP_DIR $file
    elif [[ "VARCHAR" == "$dataType" ]]; then
      true > $TEMP_DIR
      sed "s/VARCHAR/ VARCHAR/g" $file >> $TEMP_DIR
      true > $file
      cp $TEMP_DIR $file
    else
      echo ${dorisDataTypeArr[i]}
      echo "Doris中数据类型无此数据类型或者算法暂不支持的类型${dorisDataTypeArr[i]}"
    fi



  done

  echo "********完成数据类型前添加空格********"
}


# 遍历并处理文件
ls temp/*|while read listfile
do
  # 读取文件
  operate "$listfile"
  # 3行合为一行
  compose "$TARGET_DIR"
  addLineEnd "$RESULT_CREATE_DIR"
  # 替换所有空格
  replaceAllBlank "$RESULT_CREATE_DIR"
  # Doris数据类型前添加空格
  addDataTypeBlank "$RESULT_CREATE_DIR"



done

