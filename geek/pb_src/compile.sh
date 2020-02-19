echo $PWD
for file in $PWD/*.proto;
  do filename=${file##*/} && echo $filename && protoc -I=$PWD --descriptor_set_out=$PWD/../pb/$filename $file;
done;
