#!/usr/bin/env bash
#外部传入参数说明
# $1: 'single' 单卡训练； 'multi' 多卡训练； 'cpu' cpu 训练
#获取当前路径
cur_path=`pwd`
model_name=$2
temp_path=$(echo $2|awk -F '_' '{print $2}')

echo "$2 infer"

#路径配置
root_path=$cur_path/../../
code_path=$cur_path/../../PaddleRec/models/multitask/${temp_path}
log_path=$root_path/log/multitask/
mkdir -p $log_path
#临时环境更改

#访问RD程序
print_info(){
if [ $1 -ne 0 ];then
    echo "exit_code: 1.0" >> ${log_path}/$2.log
    cat ${log_path}/$2.log
    mv ${log_path}/$2.log ${log_path}/F_$2.log
    echo -e "\033[31m ${log_path}/F_$2 \033[0m"
else
    cat ${log_path}/$2.log
    echo "exit_code: 0.0" >> ${log_path}/$2.log
    mv ${log_path}/$2.log ${log_path}/S_$2.log
    echo -e "\033[32m ${log_path}/S_$2 \033[0m"
fi
}

cd $code_path
echo -e "\033[32m `pwd` infer \033[0m";

# mmoe模型收敛性运行
# 单卡动态图预测收敛性
if [ "$1" = "linux_dy_gpu1_con" ]; then
    # 修改use_gpu选项
    sed -i "s/  use_gpu: False/  use_gpu: True/g" config_bigdata.yaml
    python -u ../../../tools/infer.py -m config_bigdata.yaml -o runner.infer_load_path="output_model_mmoe_all_dy" > ${log_path}/$2.log 2>&1
    print_info $? $2

# 单卡静态图预测收敛性
elif [ "$1" = "linux_st_gpu1_con" ]; then
    # 修改use_gpu选项
    sed -i "s/  use_gpu: False/  use_gpu: True/g" config_bigdata.yaml
    python -u ../../../tools/static_infer.py -m config_bigdata.yaml -o runner.infer_load_path="output_model_mmoe_all_st" > ${log_path}/$2.log 2>&1
    print_info $? $2

fi


if [ "$1" = "linux_dy_gpu1" ];then #单卡
    sed -i "s/  use_gpu: False/  use_gpu: True/g" config_bigdata.yaml
    python -u ../../../tools/infer.py -m config_bigdata.yaml -o runner.infer_load_path="output_model_mmoe_all_dy_gpu1" > ${log_path}/$2.log 2>&1
    print_info $? $2
elif [ "$1" = "linux_dy_gpu2" ];then #多卡
    sed -i "s/  use_gpu: False/  use_gpu: True/g" config_bigdata.yaml
    # 多卡的运行方式
    python -m paddle.distributed.launch ../../../tools/infer.py -m config_bigdata.yaml -o runner.infer_load_path="output_model_mmoe_all_dy_gpu2" >${log_path}/$2.log 2>&1
    print_info $? $2
    mv $code_path/log $log_path/$2_dist_log
elif [ "$1" = "linux_dy_cpu" ];then
    sed -i "s/  use_gpu: True/  use_gpu: False/g" config_bigdata.yaml
    python -u ../../../tools/infer.py -m config_bigdata.yaml -o runner.infer_load_path="output_model_mmoe_all_dy_cpu" > ${log_path}/$2.log 2>&1
    print_info $? $2

elif [ "$1" = "linux_st_gpu1" ];then #单卡
    sed -i "s/  use_gpu: False/  use_gpu: True/g" config_bigdata.yaml
    python -u ../../../tools/static_infer.py -m config_bigdata.yaml -o runner.infer_load_path="output_model_mmoe_all_st_gpu1" > ${log_path}/$2.log 2>&1
    print_info $? $2
elif [ "$1" = "linux_st_gpu2" ];then #多卡
    sed -i "s/  use_gpu: False/  use_gpu: True/g" config_bigdata.yaml
    # 多卡的运行方式
    python -m paddle.distributed.launch ../../../tools/static_infer.py -m config_bigdata.yaml -o runner.infer_load_path="output_model_mmoe_all_st_gpu2" >${log_path}/$2.log 2>&1
    print_info $? $2
    mv $code_path/log $log_path/$2_dist_log

elif [ "$1" = "linux_st_cpu" ];then
    sed -i "s/  use_gpu: True/  use_gpu: False/g" config_bigdata.yaml
    python -u ../../../tools/static_infer.py -m config_bigdata.yaml -o runner.infer_load_path="output_model_mmoe_all_st_cpu" > ${log_path}/$2.log 2>&1
    print_info $? $2
else
    echo "$model_name infer.sh  parameter error "
fi
