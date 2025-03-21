import random
import uuid

ADJECTIVES = [
    "Happy", "Sleepy", "Grumpy", "Silly", "Clever", "Brave", "Mighty", "Swift",
    "Sneaky", "Lucky", "Jolly", "Witty", "Fancy", "Lazy", "Bouncy", "Speedy"
]

CARTOON_NAMES = [
    "Mickey", "Donald", "Goofy", "Pikachu", "Snoopy", "SpongeBob", "Mario",
    "Sonic", "Garfield", "Homer", "Bugs", "Popeye", "Scooby", "Jerry", "Tweety"
]

def generate_username():
    """Generate a random username combining an adjective and cartoon name"""
    adj = random.choice(ADJECTIVES)
    name = random.choice(CARTOON_NAMES)
    return f"{adj}{name}"

def generate_dummy_rfid():
    """Generate a dummy RFID starting with 'DUMMY-' followed by a UUID4"""
    return f"DUMMY-{uuid.uuid4().hex[:8]}"