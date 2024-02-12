
if [[ $1 == "ostry" ]]; then
  python3 get_token.py
elif [[ $1 == "test" ]]; then
  python3 get_token-test.py
else
  echo "Zadej parametr ostry|test"; exit
fi