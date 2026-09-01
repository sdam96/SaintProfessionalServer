@echo off

mysqldump -h localhost -u root -P3307 -p12345 ^
    --no-create-info ^
    --skip-extended-insert ^
    --complete-insert ^
    --skip-add-locks ^
    --skip-disable-keys ^
    --skip-comments ^
    --order-by-primary ^
    --hex-blob ^
    --default-character-set=utf8mb4 ^
    topadministrativo > snap_%1.sql
echo snapshot guardado: snap_%1.sql