crear un proyecto en git llamado "xiaozhi_rpi"
con las licencias de locales y el usuario es  "siliconvalleyar-oss"
crear archivos en docs/ *.md como extension para documentar como instalar y confgurar xiaozhi para una raspberry
crear una carpeta llamada scripts/ donde se van a alosjar los bash para instalar dependecias para el xiaozhi

se puede acceder a la raspberry sin contraseña

LINK_PROJECT_GIT=(aqui va el link de la ruta del proyecto)

ssh joy@raspberry.local "cd /home/joy/src && git clone $LINK_PROJECT_GIT && git pull && python3 main.py"






queda pendiente configurar y distriburir los pines para hacer funcionar mic inmp441 para el proyecto "Xiaozhi"

*es decir para generar codigo configuracion hacerlo localmente y pushear , luego paara pruebas , es solo de modo remoto











sudo apt-get install -y pulseaudio-utils

sudo apt-get install -y python3-pyaudio portaudio19-dev ffmpeg libopus0 libopus-dev build-essential python3-venv


wget -O Miniconda3-latest-Linux-aarch64.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh


chmod +x Miniconda3-latest-*.sh

./Miniconda3-latest-*.sh

Descargue el paquete de instalación de Miniconda:

wget -O Miniconda3-latest-Linux-aarch64.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh

Agregue permisos de ejecución al script de instalación:

chmod +x Miniconda3-latest-*.sh

Ejecuta el script de instalación:

./Miniconda3-latest-*.sh

Durante el proceso de instalación:

Cuando aparezca el acuerdo de licencia → Pulse la Entertecla para desplazarse lentamente o pulse qpara saltar directamente.

Escriba yespara aceptar el acuerdo. Seleccione la ruta de instalación (la predeterminada es $HOME/miniconda3) → Pulse Enterdirectamente para confirmar.

Si se debe inicializar Miniconda → Tipo yes(recomendado).

######################################
###Configurar variables de entorno:###
######################################
 nano ~/.bashrc
Agregue al final del archivo: Guardar y salir: Presione , presione , presione Haga que la configuración surta efecto inmediatamente:
export PATH="$HOME/miniconda3/bin:$PATH"

Ctrl + XYEnter
source ~/.bashrc


Reinicie el robot Xiaozhi:
python main.py

{

  “OPCIONES_DEL_SISTEMA”: {

    “ID_CLIENTE”: “a254fb22-f54f-48ca-8e32-29557542cfcf1”,

    “ID_DEL_DISPOSITIVO”: “dc:a6:32:7f:db:91”,

    "RED": {

      “OTA_VERSION_URL”: “https://api.tenclass.net/xiaozhi/ota/”,

      “WEBSOCKET_URL”: “wss://api.tenclass.net/xiaozhi/v1/”,

      “WEBSOCKET_ACCESS_TOKEN”: “test-token”,

      “MQTT_INFO”: {

        “punto final”: “mqtt.xiaozhi.me”,

        “client_id”: “GID_test@@@dc_a6_32_7f_db_91@@@a254fb22-f54f-48ca-8e32-29557542cfcf”,

        “nombre de usuario”: “eyJpcCI6IjExNi4zMS4yNTUuMTIifQ==”,

        “contraseña”: “ODxGAmYTSPuc5ajG0YpiT+cK5DQATnUCpUeoLY+K4Z8=”,

        “publish_topic”: “servidor-dispositivo”,

        “tema_suscripción”: “nulo”

      },

      “VERSIÓN_DE_ACTIVACIÓN”: “v2”,

      “URL_DE_AUTORIZACIÓN”: “https://xiaozhi.me/”

    }

  },

  “OPCIONES_DE_PALABRA_DE_DESPERTAR”: {

    “USE_WAKE_WORD”: verdadero,

    “MODEL_PATH”: “models/vosk-model-small-cn-0.22”,

    “PALABRAS_DE_DESPERTAR”: [

      “小智”,

      “小美”,

    ]

  },

  “TEMPERATURE_SENSOR_MQTT_INFO”: {

    “punto final”: “你的Mqtt连接地址”,

    “puerto”: 1883,

    “nombre de usuario”: “admin”,

    “contraseña”: “123456”,

    “publish_topic”: “sensors/temperature/command”,

    “subscribe_topic”: “sensors/temperature/device_001/state”

  },

  “ASISTENTE_DOMÉSTICO”: {

    “URL”: “http://localhost:8123”,

    “TOKEN”: “”,

    "DISPOSITIVOS": []

  },

  “CÁMARA”: {

    “índice_de_cámara”: 1,

    “frame_width”: 640,

    “frame_height”: 480,

    “fps”: 30,

    “Loacl_VL_url”: “https://open.bigmodel.cn/api/paas/v4/”,

    “VLapi_key”: “90edcea408a4442295cb5cd2ab1752914.iQLrZg76zUpOJgBJ”,

    “modelos”: “glm-4v-flash”

  }

}







#################################
wget -O vosk-model-small-cn-0.22.zip https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip

Coloque el modelo de voz descargado en el directorio “models” especificado:

cd  py-xiaozhi/

mkdir models

cd models

mv ~/vosk-model-small-cn-0.22.zip ./

##################################
