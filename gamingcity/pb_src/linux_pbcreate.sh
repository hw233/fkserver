for file in ./*.proto
do protoc -I=./ --descriptor_set_out=../pb/$file $file;
done