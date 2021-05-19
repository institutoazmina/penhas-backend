docker run --rm -it --name pgloader dimitri/pgloader:latest bash

echo '' > foo.txt
echo "LOAD DATABASE" >> foo.txt
echo "     FROM      mysql://root:mypass@172.17.0.3/penhas_prod" >> foo.txt
echo "     INTO postgresql://postgres:pass@172.17.0.1/penhas_prod_pg" >> foo.txt
echo "      alter schema 'penhas_prod' rename to 'public'" >> foo.txt
echo "" >> foo.txt
echo "" >> foo.txt
echo " CAST type tinyint drop typemod to boolean using tinyint-to-boolean;" >> foo.txt

pgloader -v foo.txt

