import random

ADJECTIVES = [
    "Glad", "Morsom", "Smart", "Flink", "Ivrig",
    "Fin", "Snill", "Modig", "Sterk", "Blid",
    "Grei", "Heldig", "Mektig", "Flott", "Rask",
    "Kvikk", "Lystig", "Super", "Trygg", "Munter"
]

CHARACTERS = [
    "Pikachu", "Mario", "Ingve", "Kaptein", "Nasse",
    "Snoopy", "Mickey", "Fantorangen", "Karius", "Baktus",
    "Groot", "Donald", "Pompel", "Garfield", "Pusur",
    "Sabeltann", "Ludvig", "Charmander", "Plumbo", "Kongen"
]

def generate_username():
    """Generate a random username combining an adjective and a character name."""
    adjective = random.choice(ADJECTIVES)
    character = random.choice(CHARACTERS)
    return f"{adjective}{character}"

def generate_temp_password():
    """Generate a temporary password for new users."""
    return "1111"  # Default temporary password 