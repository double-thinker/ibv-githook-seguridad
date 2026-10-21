# Demo: hook de seguridad en git (pre-commit)

Repositorio de ejemplo para la sesión de ciberseguridad del IBV.

Si no podemos usar GitLab CI, podemos hacer parte del control de seguridad en el propio
equipo de cada desarrollador con un hook de git versionado en el repositorio. Este hook
se ejecuta antes de cada `git commit` y hace dos cosas:

1. **Escaneo de dependencias (bloqueante).** Ejecuta `pip-audit -r requirements.txt`, un
   escáner real que consulta las bases de datos públicas de vulnerabilidades (PyPI
   Advisory Database / OSV). Si encuentra alguna, el commit no se hace.
2. Revisión del diff por un agente de IA (opcional). Si tienes `claude` o `codex`
   instalado, le pasa `git diff --cached` en modo solo lectura y le pide un veredicto
   (`VEREDICTO: OK` o `VEREDICTO: BLOQUEAR`) con los hallazgos. Por defecto solo avisa;
   con `AGENT_REVIEW_STRICT=1` bloquea el commit si el veredicto es BLOQUEAR. Si no hay
   ningún agente instalado, se salta con un aviso.

La aplicación (`app.py`) es mínima: descarga una URL con `requests`. Lo importante es
`requirements.txt`, que fija a propósito versiones antiguas con vulnerabilidades conocidas
(`requests==2.19.1`, CVE-2018-18074, y `urllib3==1.23`).

## Estructura

```
app.py                          aplicación de ejemplo
requirements.txt                dependencias (vulnerables a propósito)
setup.sh                        crea .venv con pip-audit y activa los hooks
.githooks/pre-commit            el hook
.githooks/agent-review-prompt.txt  prompt de la revisión por agente
```

## Puesta en marcha

```bash
git clone https://github.com/double-thinker/ibv-githook-seguridad.git
cd ibv-githook-seguridad
./setup.sh
```

`setup.sh` crea un entorno virtual `.venv` con `pip-audit` y ejecuta
`git config core.hooksPath .githooks`, que le dice a git que use los hooks de la carpeta
versionada `.githooks/` en lugar de `.git/hooks/` (que no se versiona). Cada persona que
clone el repo tiene que ejecutar `setup.sh` una vez.

## Ejercicio

1. Intenta hacer un commit cualquiera:

   ```bash
   echo "# prueba" >> app.py
   git commit -am "Mi cambio"
   ```

   El hook lo bloquea y muestra la tabla de vulnerabilidades con la versión que las
   corrige (columna `Fix Versions`).

2. Arregla `requirements.txt` subiendo las versiones a unas sin vulnerabilidades. Puedes
   hacerlo a mano o pedírselo a tu agente, por ejemplo: "arregla las vulnerabilidades que
   reporta pip-audit en requirements.txt". Puedes comprobarlo sin hacer commit con:

   ```bash
   .venv/bin/pip-audit -r requirements.txt
   ```

   Ojo: también cuentan las dependencias indirectas (`idna`, `certifi`...). Si las fijas
   tú, también tienen que estar al día.

3. Vuelve a hacer el commit:

   ```bash
   git commit -am "Actualizo dependencias vulnerables"
   ```

   Ahora pasa el escaneo y, si tienes un agente instalado, verás su revisión del diff.
   Para probar el modo estricto: `AGENT_REVIEW_STRICT=1 git commit ...`. Para desactivar
   la revisión por agente: `AGENT_REVIEW=0 git commit ...`.

## Otros lenguajes: PHP/Joomla, Node...

El mismo esquema sirve para otros ecosistemas cambiando el escáner. En el hook hay una
línea comentada con [osv-scanner](https://google.github.io/osv-scanner/), que entiende
`composer.lock` (PHP, Joomla), `package-lock.json` (Node) y muchos otros lockfiles:

```bash
osv-scanner scan source -r .
```

## Limitaciones: por qué esto también va en CI

Un hook local es una ayuda, no un control. Cualquiera puede saltárselo con:

```bash
git commit --no-verify
```

o simplemente no ejecutar `setup.sh`. Por eso, en un entorno real, el mismo escaneo debe
repetirse en el servidor (CI/CD, o un hook del lado del servidor) donde el desarrollador no
lo puede desactivar. El hook local sirve para enterarse antes y más barato; la CI es la que
garantiza que no entra nada vulnerable.

Además, una base de datos de vulnerabilidades cambia cada día: un `requirements.txt` que
hoy pasa puede fallar mañana. Eso es lo esperado.
