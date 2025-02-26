import random

ADJECTIVES = [
    "Happy", "Bouncy", "Clever", "Dazzling", "Eager",
    "Fancy", "Gentle", "Heroic", "Iconic", "Jolly",
    "Kind", "Lucky", "Mighty", "Noble", "Peppy",
    "Quick", "Radiant", "Super", "Trusty", "Upbeat"
]

CHARACTERS = [
    "Pikachu", "Mario", "Sonic", "Yoshi", "Kirby",
    "Snoopy", "Mickey", "SpongeBob", "Totoro", "Stitch",
    "Groot", "Baymax", "Doraemon", "Garfield", "Goku",
    "Pooh", "Simba", "Aang", "Charmander", "Chopper"
]

def generate_username():
    """Generate a random username combining an adjective and a character name."""
    adjective = random.choice(ADJECTIVES)
    character = random.choice(CHARACTERS)
    return f"{adjective}{character}"

def generate_temp_password():
    """Generate a temporary password for new users."""
    return "1111"  # Default temporary password 