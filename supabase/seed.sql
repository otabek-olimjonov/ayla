-- =============================================================================
-- Ayla – Seed Data
-- =============================================================================
-- Run: supabase db seed   OR   psql -f seed.sql
-- Purpose: Populate the articles table with starter content for local dev.
-- All free-tier articles. Add is_paid = true articles for premium testing.
-- =============================================================================

INSERT INTO public.articles
  (title_uz, title_ru, body_uz, body_ru, category, is_paid, published_at)
VALUES

-- ---------------------------------------------------------------------------
-- CYCLE articles (free)
-- ---------------------------------------------------------------------------
(
  'Hayz sikli nima?',
  'Что такое менструальный цикл?',
  'Hayz sikli — bu ayolning tuxumdonlarida tuxum hujayra etilishi va bachadonning homiladorlikka tayyorlanishi jarayoni. Odatda 21 dan 35 kungacha davom etadi. Sikl 4 fazadan iborat: hayz, follikulyar, ovulyatsiya va lyuteal.',
  'Менструальный цикл — это процесс созревания яйцеклетки в яичниках и подготовки матки к беременности. Обычно длится от 21 до 35 дней и состоит из 4 фаз: менструальной, фолликулярной, овуляторной и лютеиновой.',
  'cycle', false, now() - interval '7 days'
),
(
  'Hayz og''rig''ini kamaytirish usullari',
  'Как уменьшить менструальную боль',
  'Hayz paytidagi og''riq (dismenoreya) ko''p ayollarda uchraydi. Issiq kompres qo''yish, engil jismoniy mashqlar, gidratatsiya va magniy boyligi yuqori ovqatlar iste''mol qilish yordam beradi. Og''riq juda kuchli bo''lsa, shifokor bilan maslahatlashing.',
  'Менструальные боли (дисменорея) встречаются у многих женщин. Помогают: грелка, лёгкие упражнения, достаточное питьё и продукты, богатые магнием. При сильных болях обратитесь к врачу.',
  'cycle', false, now() - interval '6 days'
),
(
  'PMS: sabablari va nima qilish kerak',
  'ПМС: причины и что делать',
  'Premenstrual sindrom (PMS) — hayzdan 1-2 hafta oldin paydo bo''ladigan jismoniy va hissiy o''zgarishlar. Kayfiyat o''zgarishi, charchoq, shishish kabi belgilar kuzatilishi mumkin. Uyqu tartibini saqlash, stress boshqaruvi va vitamin B6 qabul qilish yordam berishi mumkin.',
  'Предменструальный синдром (ПМС) — физические и эмоциональные изменения за 1-2 недели до менструации. Могут наблюдаться перепады настроения, усталость, отёчность. Помогут: режим сна, управление стрессом и витамин B6.',
  'cycle', false, now() - interval '5 days'
),
(
  'Ovulyatsiya kuni qanday aniqlanadi?',
  'Как определить день овуляции?',
  'Ovulyatsiya odatda hayz siklining o''rtasida sodir bo''ladi. Bazal tana haroratini kuzatish, servikal shilimshiqning o''zgarishi va ovulyatsiya test tasmalari — eng ishonchli usullar. Ilovamizda harorat va belgilarni qayd eting va tizim siz uchun taxmin qilsin.',
  'Овуляция обычно происходит в середине цикла. Измерение базальной температуры, наблюдение за цервикальной слизью и тест-полоски на овуляцию — самые надёжные методы. Вносите данные в приложение, и система сделает расчёт за вас.',
  'cycle', false, now() - interval '4 days'
),

-- ---------------------------------------------------------------------------
-- NUTRITION articles (free)
-- ---------------------------------------------------------------------------
(
  'Hayz davridagi to''g''ri ovqatlanish',
  'Правильное питание во время менструации',
  'Hayz paytida temir va magniyga boy ovqatlar iste''mol qiling: yashil barglar, qo''ng''ir guruch, loviya va qovoq urug''lari. Tuz va kofeini cheklang — shishishni kamaytiradi. Ko''proq suv iching.',
  'Во время менструации употребляйте продукты, богатые железом и магнием: листовые овощи, бурый рис, фасоль, тыквенные семечки. Ограничьте соль и кофеин — это снизит отёчность. Пейте больше воды.',
  'nutrition', false, now() - interval '3 days'
),
(
  'Hormonlar uchun foydali ozuqalar',
  'Продукты для гормонального баланса',
  'Gormon balansini saqlash uchun om-3 yog'' kislotalari (baliq, zig''ir urug''lari), antioxidantlarga boy mevalar, va fermentlangan ovqatlar (kefir, yogurt) foydali. Qayta ishlangan oziq-ovqat va qant iste''molini kamaytiring.',
  'Для гормонального баланса полезны омега-3 жирные кислоты (рыба, льняное семя), фрукты, богатые антиоксидантами, и ферментированные продукты (кефир, йогурт). Сократите потребление обработанной пищи и сахара.',
  'nutrition', false, now() - interval '2 days'
),

-- ---------------------------------------------------------------------------
-- MENTAL HEALTH articles (free)
-- ---------------------------------------------------------------------------
(
  'Hayz oldi davrida kayfiyat o''zgarishi',
  'Перепады настроения перед менструацией',
  'Lyuteal fazada progesteron va estrogen darajasining pasayishi kayfiyat o''zgarishiga olib keladi. Bu tabiiy jarayon. Mindfulness, jismoniy faollik va yaqinlaringiz bilan muloqot yordam beradi. Agar simptomlar juda kuchli bo''lsa, PMDD (premenstrual disforik buzilish) haqida shifokor bilan gaplashing.',
  'В лютеиновой фазе снижение уровня прогестерона и эстрогена вызывает перепады настроения. Это естественный процесс. Помогают: майндфулнес, физическая активность и общение с близкими. Если симптомы очень сильные — поговорите с врачом о ПМДР.',
  'mental_health', false, now() - interval '1 day'
),

-- ---------------------------------------------------------------------------
-- PREGNANCY articles (free)
-- ---------------------------------------------------------------------------
(
  'Homiladorlikning birinchi trimestrida nima kutiladi?',
  'Чего ожидать в первом триместре беременности?',
  'Birinchi trimestr (1-12 hafta) — ko''ngil aynishi, charchoq va ko''krak og''rig''i keng tarqalgan. Folik kislota qabul qilishni boshlang (agar hali qilmagan bo''lsangiz). Shifokor bilan dastlabki ko''rik uchun uchrashuv tayinlang.',
  'Первый триместр (1-12 недель) — тошнота, усталость и болезненность груди распространены. Начните приём фолиевой кислоты (если ещё не начали). Запишитесь на первый визит к врачу.',
  'pregnancy', false, now()
),

-- ---------------------------------------------------------------------------
-- PREMIUM CYCLE articles (paid)
-- ---------------------------------------------------------------------------
(
  'Unumdorlikni oshirish uchun 7 ta maslahat',
  '7 советов для повышения фертильности',
  'Unumdorlikni oshirish uchun: ideal vaznga erishish, sigaretni tashlab qo''yish, alkogolni cheklash, stress darajasini pasaytirish, to''g''ri ovqatlanish, muntazam jismoniy mashqlar va harorat kuzatish zarur. Batafsil ma''lumot uchun ushbu maqolani o''qing.',
  'Для повышения фертильности: достижение здорового веса, отказ от курения, ограничение алкоголя, снижение стресса, правильное питание, регулярные упражнения и измерение базальной температуры. Подробнее — в этой статье.',
  'cycle', true, now()
),
(
  'Bazal tana haroratini qanday o''lchash kerak?',
  'Как правильно измерять базальную температуру?',
  'Bazal tana harorati (BTH) har kuni uyg''onganingizdan so''ng, hech qanday harakat qilmasdan, og''izda yoki rektal termometr bilan o''lchanadi. 0.1-0.2°C ko''tarilish ovulyatsiyadan keyin sodir bo''lgan degan ma''noni bildiradi. Natijalarni grafik ko''rinishida kuzating.',
  'Базальная температура (БТ) измеряется каждое утро сразу после пробуждения, без движения, оральным или ректальным термометром. Повышение на 0,1-0,2°C указывает на произошедшую овуляцию. Ведите график для отслеживания.',
  'cycle', true, now()
);
