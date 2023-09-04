import RPi.GPIO as GPIO
import time
import telepot
from telepot.loop import MessageLoop
import requests
from ubidots import ApiClient

# Define GPIO pins and constants
PIR = 17  # masuk
PIR2 = 14  # keluar
LED = 15
jumlah_orang = 0

# Set up GPIO
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(PIR, GPIO.IN)
GPIO.setup(PIR2, GPIO.IN)
GPIO.setup(LED, GPIO.OUT)

# Initialize telepot bot
bot = telepot.Bot('5990716632:AAEkO6pKs1obx75fPPPaaNup1xS5Nje3qBs')
chat_id = None

# Handle incoming messages
def handle(msg):
    global chat_id
    chat_id = msg['chat']['id']
    telegramText = msg['text']
    print('Message received from ' + str(chat_id))
    if telegramText == '/start':
        bot.sendMessage(chat_id, 'Welcome to Smart Library')

# Send data to Ubidots
def sendToUbidots(count):
    TOKEN = "BBFF-BLy2UooA53bN4Sz2wX0gmCxPkFP0uD"
    DEVICE_LABEL = "smart-library-dashboard"
    VARIABLE_LABEL = "jumlah-pengunjung"
    
    payload = {
        "jumlah-orang": count
    }

    headers = {"X-Auth-Token": TOKEN, "Content-Type": "application/json"}
    url = "http://industrial.api.ubidots.com"
    url = "{}/api/v1.6/devices/{}".format(url, DEVICE_LABEL)
    req = requests.post(url=url, headers=headers, json=payload)

    print(req.status_code, req.json())
    if req.status_code >= 400:
        print("[ERROR] Could not send data to Ubidots")
    else:
        print("[INFO] Data sent to Ubidots successfully")

# Main function for motion detection
def main():
    global jumlah_orang
    
    try:
        while True:  # Add an infinite loop to keep monitoring
            if GPIO.input(PIR) == 1:
                jumlah_orang += 1
                print("Ada orang masuk")
                print("Jumlah orang", jumlah_orang)
                GPIO.output(LED, GPIO.HIGH)
                sendToUbidots(jumlah_orang)
                time.sleep(10)

            elif GPIO.input(PIR2) == 1:
                jumlah_orang -= 1
                print("Ada orang keluar")
                print("Jumlah orang", jumlah_orang)
                GPIO.output(LED, GPIO.LOW)
                sendToUbidots(jumlah_orang)
                time.sleep(10)
    except KeyboardInterrupt:
        GPIO.cleanup()

# Start the main function
if __name__ == "__main__":
    main()
