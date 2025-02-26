import random

ADJECTIVES = [
    "Glad", "Morsom", "Smart", "Flink", "Ivrig",
    "Fin", "Snill", "Modig", "Sterk", "Blid",
    "Grei", "Heldig", "Mektig", "Flott", "Rask",
    "Kvikk", "Lystig", "Super", "Trygg", "Munter"
]

CHARACTERS = [
    "Pikachu", "Mario", "Ivo", "Kaptein", "Flåklypa",
    "Snoopy", "Mickey", "Fantorangen", "Karius", "Baktus",
    "Groot", "Nøste", "Pompel", "Garfield", "Goku",
    "Pilt", "Ludvig", "Thorbjørn", "Charmander", "Plumbo"
]

def generate_username():
    """Generate a random username combining an adjective and a character name."""
    adjective = random.choice(ADJECTIVES)
    character = random.choice(CHARACTERS)
    return f"{adjective}{character}"

def generate_temp_password():
    """Generate a temporary password for new users."""
    return "1111"  # Default temporary password 