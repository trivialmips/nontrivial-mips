if [ -f $(echo $1 | sed 's/s$/genans.py/') ]; then
	python $(echo $1 | sed 's/s$/genans.py/') > $2;
else
	grep -Po "(?<=# ans:\s).*" $1 | awk -f extract_ans.awk | sed "s/\s*$//" > $2;
fi
