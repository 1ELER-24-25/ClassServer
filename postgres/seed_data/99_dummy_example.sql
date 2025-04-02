-- ============================================
-- Seed Data for Dummy Example Course
-- ============================================
-- NOTE: Replace 'Dummy Example Course' and 'dummy_lang' with actual values.
-- NOTE: Ensure course_id in subqueries matches the new course (e.g., 3 if it's the third course).

-- Insert Course
INSERT INTO courses (title, description, language)
SELECT 'Dummy Example Course', 'En kort eksempelbeskrivelse for kurset.', 'dummy_lang'
WHERE NOT EXISTS (SELECT 1 FROM courses WHERE title = 'Dummy Example Course');

-- Insert Modules for the Dummy Course (Replace course_id=3 if needed)
INSERT INTO modules (course_id, title, description, content, documentation_links, order_num) VALUES
((SELECT id from courses WHERE title = 'Dummy Example Course'), 'Første Steg', 'Beskrivelse av hva eleven skal gjøre i modul 1.',
'// Startkode for modul 1
int variabel1 = 0; // FYLL INN RIKTIG VERDI
void setup() {
  // TODO: Initialiser noe
}
void loop() {}',
'[{"title": "Link 1 Tittel", "url": "http://example.com/link1"}]',
1),
((SELECT id from courses WHERE title = 'Dummy Example Course'), 'Andre Steg', 'Beskrivelse av hva eleven skal bygge videre på i modul 2.',
'// Kode fra forrige modul...
// TODO: Legg til ny funksjonalitet her
void loop() {
  // variabel1 = ...;
}',
'[{"title": "Link 2 Tittel", "url": "http://example.com/link2"}]',
2);

-- Insert Hints for Dummy Course Modules (Replace course_id=3 if needed)
-- Module 1 (Order 1)
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Dummy Example Course') AND order_num = 1), 'Hint 1 for Modul 1.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Dummy Example Course') AND order_num = 1), 'Hint 2 for Modul 1.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 1), 'Hint 3 for Modul 1.', 3);
-- No hint 4 (Sniktitt) for module 1

-- Module 2 (Order 2)
INSERT INTO hints (module_id, hint_text, hint_number) VALUES
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Dummy Example Course') AND order_num = 2), 'Hint 1 for Modul 2.', 1),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Dummy Example Course') AND order_num = 2), 'Hint 2 for Modul 2.', 2),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Arduino Morse-kode Blinker') AND order_num = 2), 'Hint 3 for Modul 2.', 3),
((SELECT id from modules WHERE course_id = (SELECT id from courses WHERE title = 'Dummy Example Course') AND order_num = 2), 'Sniktitt på forrige modul (-10 poeng):<pre><code class="language-dummy_lang">// Startkode for modul 1\nint variabel1 = 42; // RIKTIG VERDI\nvoid setup() {\n  // Initialiser noe\n}\nvoid loop() {}</code></pre>', 4);
