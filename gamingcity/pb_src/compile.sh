for file in *.proto;
    do echo $file&&protoc -I=./ --descriptor_set_out=../pb/$file $file;
done