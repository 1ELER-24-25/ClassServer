-- ============================================
-- Seed Data for Python Intro Course
-- ============================================

-- Insert Course (if not exists - though init scripts run only once on empty DB)
INSERT INTO courses (title, description, language)
SELECT 'Introduksjon til Python', 'Et grunnleggende kurs i Python-programmering.', 'python'
WHERE NOT EXISTS (SELECT 1 FROM courses WHERE title = 'Introduksjon til Python');

-- Insert Modules
INSERT INTO modules (course_id, title, description, content, documentation_links, order_num) VALUES
((SELECT id from courses WHERE title = 'Introduksjon til Python'), 'Hei, Verden!', 'Skriv ditt første Python-program som skriver ut "Hei, Verden!" til konsollen.', 'print("...")', '[{"title": "Python print() funksjon", "url": "https://docs.python.org/3/library/functions.html#print"}]', 1),
((SELECT id from courses WHERE title = 'Introduksjon til Python'), 'Variabler', 'Lær om variabler ved å lagre navnet ditt i en variabel og skrive det ut.', 'navn = "Ditt Navn"\nprint(navn)', '[{"title": "Python Variabler", "url": "https://www.w3schools.com/python/python_variables.asp"}]', 2),
((SELECT id from courses WHERE title = 'Introduksjon til Python'), 'Enkel Matematikk', 'Utfør en enkel addisjon (f.eks. 5 + 7) og skriv ut resultatet.', 'resultat = 5 + 7\nprint(resultat)', '[{"title": "Python Operators", "url": "https://www.w3schools.com/python/python_operators.asp"}]', 3);

-- Insert Hints
-- Hints for Module 1
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Introduksjon til Python') AND order_num = 1), 'Du trenger `print()`-funksjonen.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Introduksjon til Python') AND order_num = 1), 'Tekst i Python må være omgitt av anførselstegn (`"` eller `´`).', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Introduksjon til Python') AND order_num = 1), 'Hele kommandoen er `print("Hei, Verden!")`.', 3);

-- Hints for Module 2
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Introduksjon til Python') AND order_num = 2), 'Bruk `=` for å tilordne en verdi til en variabel.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Introduksjon til Python') AND order_num = 2), 'Husk anførselstegn rundt navnet ditt, siden det er en tekststreng.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Introduksjon til Python') AND order_num = 2), 'Du kan skrive ut variabelens verdi med `print(variabelnavn)`.', 3);

-- Hints for Module 3
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Introduksjon til Python') AND order_num = 3), 'Bruk `+`-tegnet for addisjon.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Introduksjon til Python') AND order_num = 3), 'Lagre resultatet i en variabel før du skriver det ut.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Introduksjon til Python') AND order_num = 3), 'Koden kan se slik ut: `sum = 5 + 7\nprint(sum)`.', 3);
