#!/bin/bash
# 资源文件路径
RESOURCE_FILE=resource/resource.txt
# 临时文件夹
TEMP_DIR=temp
# 目标文件路径
TEMP_COPYRESOURCE_FILE=./temp/copyResource.txt
# 临时数据表
TEMP_TEMP_FILE=./temp/temp.txt
# 最终结果-建表语句
RESULT_CREATE_FILE=./target/result_create.txt
# 最终结果-查询语句
RESULT_SELECT_FILE=./target/result_select.txt


# 清空文件历史数据
#echo "开始清空历史数据。。。"
true > $RESULT_CREATE_FILE
true > $RESULT_SELECT_FILE
#echo "完成清空历史数据。。。"

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

  for line in `cat $file`
  do
#    echo $line
    oracleToDorisType "$line"
    local retCode=$?
    if [ $retCode -eq 0 ]; then
      echo $line >> $TEMP_COPYRESOURCE_FILE
    elif [ $retCode -eq 1 ]; then
      echo "VARCHAR(" >> $TEMP_COPYRESOURCE_FILE
    elif [ $retCode -eq 2 ]; then
      echo "INT(" >> $TEMP_COPYRESOURCE_FILE
    elif [ $retCode -eq 3 ]; then
      echo "CHAR(" >> $TEMP_COPYRESOURCE_FILE
    elif [ $retCode -eq 4 ]; then
      echo "DATE-数据类型之后需要删除(" >> $TEMP_COPYRESOURCE_FILE
    fi

  done
}

# Oracle中需要转换成Doris
oracleToDorisType(){
  local retStr=0

  local line=$1
   # Oracle中需要转换成Doris中Varchar的类型
  local oracleToVarchar=(VARCHAR VARCHAR2 NCLOB CLOB)
  local isReplace=0
  for(( i=0;i<${#oracleToVarchar[@]};i++))
  do
    #${#array[@]}获取数组长度用于循环
    local dataType=${oracleToVarchar[i]}
    if [[ "$line" = "$dataType" ]]; then
      isReplace=1
    fi
  done
  if [ $isReplace -eq 1 ]; then
    retStr=1
    return $retStr
  fi

  # Oracle中需要转换成Doris中INT的类型
  local oracleToINT=(NUMBER INTEGER INT)
  isReplace=0
  for(( i=0;i<${#oracleToINT[@]};i++))
  do
    #${#array[@]}获取数组长度用于循环
    local dataType=${oracleToINT[i]}
    if [[ "$line" = "$dataType" ]]; then
      isReplace=1
    fi
  done
  if [ $isReplace -eq 1 ]; then
    retStr=2
    return $retStr
  fi

  # Oracle中需要转换成Doris中CHAR的类型
  local oracleToCHAR=(CHAR NCHAR)
  isReplace=0
  for(( i=0;i<${#oracleToCHAR[@]};i++))
  do
    #${#array[@]}获取数组长度用于循环
    local dataType=${oracleToCHAR[i]}
    if [[ "$line" = "$dataType" ]]; then
      isReplace=1
    fi
  done
  if [ $isReplace -eq 1 ]; then
    retStr=3
    return $retStr
  fi

  # Oracle中需要转换成Doris中CHAR的类型
  local oracleToDATE=(DATE)
  isReplace=0
  for(( i=0;i<${#oracleToDATE[@]};i++))
  do
    #${#array[@]}获取数组长度用于循环
    local dataType=${oracleToDATE[i]}
    if [[ "$line" = "$dataType" ]]; then
      isReplace=1
    fi
  done
  if [ $isReplace -eq 1 ]; then
    retStr=4
    return $retStr
  else
    return $retStr
  fi
}

# 3行合为一行
compose(){
  local file=$1
  sed 'N;N;s/\n/ /g' $file >> $RESULT_CREATE_FILE
}

# 文件行尾处理
addLineEnd(){
  local file=$1
  echo "****************"
  sed "s/$/&),/g" $file >> $TEMP_TEMP_FILE
  true > $file
  cp $TEMP_TEMP_FILE $file
}

# 替换每行第二个空格
replaceAllBlank(){
  true > $TEMP_TEMP_FILE
  local file=$1
#  echo "********开始替换每行第二个空格********"
  sed "s/ //2" $file >> $TEMP_TEMP_FILE
  true > $file
  cp $TEMP_TEMP_FILE $file
#  echo "********完成替换每行第二个空格********"
}

# 生成查询语句
generalSelect(){
  echo "********开始生成查询语句********"
  true > $TEMP_TEMP_FILE
  local file=$1
  cat $RESULT_CREATE_FILE | awk -F " " '{print $1}' > $RESULT_SELECT_FILE
  sed "s/$/&,/g" $file >> $TEMP_TEMP_FILE
  true > $file
  cp $TEMP_TEMP_FILE $file
  echo "********完成生成查询语句********"
}

# 最后一行逗号处理
handlelastLine(){
  true > $TEMP_TEMP_FILE
  local file=$1
  # 读取最后一行并替换
  cat $file | awk 'END {print}' | sed 's/,//' >> $TEMP_TEMP_FILE
  #删除最后一行
  sed -i '$d' $file
  # 在最后一行后添加
  cat $TEMP_TEMP_FILE >> $file
}

# 拼接SQL
connectSQL(){
  local file=$1
  local startStr=$2
  local endStr=$3
  sed -i "1i $startStr" $file
  echo -e $endStr >> $file

  # 去掉空行
  sed -i '/^$/d' $file
}


# 删除临时文件
delTempFile(){
  rm -rf $TEMP_DIR
}

# 删除临时文件
delTempFile
# 创建文件夹
mkdir $TEMP_DIR
# 参数处理-开始
tableName=""
tableComment=""
keyType=""
keys=""
hashParm=""
creatStartStr="CREATE TABLE "
creatEndStr=""
selectStartStr="SELECT"
selectEndStr=""
if [ "$#" -eq 5 ]; then
  tableName=$1
  if [ "$2" -eq 1 ]; then
    keyType="UNIQUE"
  elif [ "$2" -eq 2 ]; then
    keyType="DUPLICATE"
  else
    echo "主键类型参数异常，请重新配置 1代表UNIQUE 2代表DUPLICATE"
    exit 1
  fi
  keys=$3
  hashParm=$4
  tableComment=$5
  creatStartStr="$creatStartStr$tableName ("
  creatEndStr="\n)\n$keyType KEY($keys)\nCOMMENT \"$tableComment\"\nDISTRIBUTED BY HASH($hashParm) BUCKETS 10\nPROPERTIES(\"replication_num\" = \"3\");"
  selectEndStr="$selectEndStr\nFROM $tableName"
elif [ "$#" -eq 0 ]; then
  echo "********请按提示输入参数********"
  echo "********请按提示输入参数********"
  read -p '请输入表名称：' tableName
  read -p '请输入主键类型(1代表UNIQUE 2代表DUPLICATE)：' keyTypeInt
  if [ "$keyTypeInt" -eq 1 ]; then
    keyType="UNIQUE"
  elif [ "$keyTypeInt" -eq 2 ]; then
    keyType="DUPLICATE"
  else
    echo "主键类型参数异常，请重新配置 1代表UNIQUE 2代表DUPLICATE"
    exit 1
  fi
  read -p '请输入主键(复合主键请用英文逗号分隔)：' keys
  read -p '请输入需要HASH字段：' hashParm
  read -p '请输入表注释：' tableComment
  creatStartStr="$creatStartStr$tableName ("
  creatEndStr="\n)\n$keyType KEY($keys)\nCOMMENT \"$tableComment\"\nDISTRIBUTED BY HASH($hashParm) BUCKETS 10\nPROPERTIES(\"replication_num\" = \"3\");"
  selectEndStr="$selectEndStr\nFROM $tableName"
  echo "********请等待。。。正在生成。。。********"
  echo "********请等待。。。正在生成。。。********"
else
  echo "参数不是5个，格式为：表名称 主键类型 主键 HASH字段 表注释"
  exit 1
fi
# 参数处理-结束
# 遍历并处理文件
ls resource/*|while read listfile
do
  # 读取文件
  operate "$listfile"
  # 3行合为一行
  compose "$TEMP_COPYRESOURCE_FILE"
  addLineEnd "$RESULT_CREATE_FILE"
  # 替换每行第二个空格，生成建表语句字段
  replaceAllBlank "$RESULT_CREATE_FILE"

  # 生成查询语句
  generalSelect "$RESULT_SELECT_FILE"
  # 最后一行逗号处理
  handlelastLine "$RESULT_CREATE_FILE"
  handlelastLine "$RESULT_SELECT_FILE"

  # 拼接SQL
  connectSQL "$RESULT_CREATE_FILE" "$creatStartStr" "$creatEndStr"
  connectSQL "$RESULT_SELECT_FILE" "$selectStartStr" "$selectEndStr"


  # 删除临时文件
  delTempFile

done

