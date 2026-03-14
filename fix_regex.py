files = [
    r'lib\screens\financeiro\cliente_form_screen.dart',
    r'lib\screens\financeiro\fornecedor_form_screen.dart',
]
for f in files:
    with open(f, 'r', encoding='utf-8') as fh:
        content = fh.read()
    fixed = content.replace("$');$');", "$');")
    with open(f, 'w', encoding='utf-8') as fh:
        fh.write(fixed)
    print(f'Fixed: {f}')
print('Done')
