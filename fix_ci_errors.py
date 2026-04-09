import re

with open('lib/app.dart', 'r') as f:
    app_code = f.read()

# remove debugShowCheckedModeBanner: false, if it exists
app_code = app_code.replace('        debugShowCheckedModeBanner: false,\n', '')

with open('lib/app.dart', 'w') as f:
    f.write(app_code)


with open('lib/shared/theme/gonyeti_theme.dart', 'r') as f:
    theme_code = f.read()

# Fix 1: Constructor declarations should be before non-constructor declarations
# In GonyetiThemeExtension, move `const GonyetiThemeExtension({...});` to the top, before `final Color bg;`
# Actually, the dart compiler wants it right after the class declaration.
match = re.search(r'  const GonyetiThemeExtension\(\{.*?\}\);', theme_code, re.DOTALL)
if match:
    constructor_str = match.group(0)
    theme_code = theme_code.replace(constructor_str + '\n\n', '')
    theme_code = theme_code.replace('class GonyetiThemeExtension extends ThemeExtension<GonyetiThemeExtension> {\n',
                                    'class GonyetiThemeExtension extends ThemeExtension<GonyetiThemeExtension> {\n' + constructor_str + '\n\n')

# Fix 2: prefer_const_declarations
theme_code = theme_code.replace('final colors = _darkColors;', 'const colors = _darkColors;')
theme_code = theme_code.replace('final colors = _lightColors;', 'const colors = _lightColors;')

# Fix 3: avoid_redundant_argument_values
# lib/shared/theme/gonyeti_theme.dart:184:18 (probably scaffoldBackgroundColor or cardColor that matches ThemeData defaults? We don't know exactly, but it's easier to just run `dart fix --apply`)
