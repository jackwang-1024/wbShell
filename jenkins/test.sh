#!/bin/bash
style_list=(tar10.jpg  tar11.jpg  tar12.jpg  tar13.jpg  tar14.jpg  tar15.jpg  tar1.jpg  tar2.jpg  tar3.jpg  tar4.jpg  tar5.jpg  tar6.jpg  tar7.jpg  tar8.jpg  tar9.jpg)
input_list=(in10.jpg  in11.jpg  in12.jpg  in13.jpg  in14.jpg  in15.jpg  in1.jpg  in2.jpg  in3.jpg  in4.jpg  in5.jpg  in6.jpg  in7.jpg  in8.jpg  in9.jpg)
style_pwd="/home/xiaxoue/style"
input_pwd="/home/xiaxoue/input"

for style in ${!style_list[@]};do
	python inference.py ${style_pwd}/${style} snapshot/model.ckpt-2000
	cp output/mask.png ${style_pwd}/${style%%.*}.png
done
