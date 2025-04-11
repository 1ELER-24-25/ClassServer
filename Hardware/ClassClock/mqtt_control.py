import paho.mqtt.client as mqtt
import time
from datetime import datetime

# MQTT Configuration
MQTT_SERVER = "192.168.1.100"
MQTT_PORT = 1883
MQTT_TOPIC_COMMAND = "iot/klokke/kommando"
MQTT_TOPIC_STATUS = "iot/klokke/status"

def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")
    client.subscribe(MQTT_TOPIC_STATUS)

def on_message(client, userdata, msg):
    print(f"Status: {msg.payload.decode()}")

def main():
    # Set up MQTT client
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    try:
        client.connect(MQTT_SERVER, MQTT_PORT, 60)
        client.loop_start()
    except Exception as e:
        print(f"Kunne ikke koble til MQTT-server: {e}")
        return

    while True:
        print("\nMeny:")
        print("1. Start nedtelling")
        print("2. Stopp nedtelling")
        print("3. Avslutt")
        
        valg = input("Velg handling (1-3): ")

        if valg == "1":
            print("\nAngi tid for nedtelling:")
            try:
                timer = int(input("Timer (0-23): "))
                minutter = int(input("Minutter (0-59): "))
                sekunder = int(input("Sekunder (0-59): "))
                
                if not (0 <= timer <= 23 and 0 <= minutter <= 59 and 0 <= sekunder <= 59):
                    print("Ugyldig tidsformat!")
                    continue

                print("\nVelg farge:")
                print("1. Rød")
                print("2. Grønn")
                print("3. Blå")
                print("4. Gul")
                print("5. Egen farge (HEX)")
                
                farge_valg = input("Velg farge (1-5): ")
                
                if farge_valg == "1":
                    farge = "FF0000"
                elif farge_valg == "2":
                    farge = "00FF00"
                elif farge_valg == "3":
                    farge = "0000FF"
                elif farge_valg == "4":
                    farge = "FFFF00"
                elif farge_valg == "5":
                    farge = input("Skriv inn HEX-fargekode (f.eks. FF0000 for rød): ")
                else:
                    print("Ugyldig fargevalg!")
                    continue

                # Lag MQTT-melding
                tid_str = ""
                if timer > 0:
                    tid_str += f"{timer}h"
                if minutter > 0:
                    tid_str += f"{minutter}m"
                if sekunder > 0:
                    tid_str += f"{sekunder}s"
                
                melding = f"nedtelling:{tid_str}:{farge}"
                client.publish(MQTT_TOPIC_COMMAND, melding)
                print(f"Sendt kommando: {melding}")

            except ValueError:
                print("Ugyldig input! Bruk bare tall.")

        elif valg == "2":
            client.publish(MQTT_TOPIC_COMMAND, "nedtelling:stopp")
            print("Nedtelling stoppet")

        elif valg == "3":
            print("Avslutter...")
            break

        else:
            print("Ugyldig valg!")

    client.loop_stop()
    client.disconnect()

if __name__ == "__main__":
    main()