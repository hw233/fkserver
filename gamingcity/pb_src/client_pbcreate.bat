echo ��Ҫ��װ7zip������·�����뵽path��

md client
for /r %%s in (common_*.proto) do (
	protoc.exe -I . --descriptor_set_out client/%%~ns.proto %%~ns.proto
)

7z a -tzip "client" ".\client\*.*"


pause
