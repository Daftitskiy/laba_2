-- ЧАСТЬ 2. ПРОЕКТИРОВАНИЕ ХРАНИЛИЩА ПО МЕТОДОЛОГИИ DATA VAULT 2.0
CREATE DATABASE IF NOT EXISTS `dwh_faculty_curriculum`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `dwh_faculty_curriculum`;

-- =============================================================================
-- 1. ТАБЛИЦЫ-ХАБЫ (HUBS) — БИЗНЕС-СУЩНОСТИ
-- =============================================================================

-- Хаб кафедр
CREATE TABLE `hub_department` (
    `department_hash_key` BINARY(16) NOT NULL COMMENT 'MD5-хеш от шифра кафедры',
    `load_date` DATETIME NOT NULL COMMENT 'Дата и время загрузки записи в ХД',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `department_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Бизнес-ключ: шифр кафедры',
    PRIMARY KEY (`department_hash_key`)
) ENGINE=InnoDB COMMENT='Хаб: Кафедры факультета';

-- Хаб специальностей
CREATE TABLE `hub_specialty` (
    `specialty_hash_key` BINARY(16) NOT NULL COMMENT 'MD5-хеш от кода специальности',
    `load_date` DATETIME NOT NULL COMMENT 'Дата и время загрузки записи в ХД',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `specialty_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Бизнес-ключ: код специальности по ФГОС',
    PRIMARY KEY (`specialty_hash_key`)
) ENGINE=InnoDB COMMENT='Хаб: Направления подготовки / специальности';

-- Хаб академических групп
CREATE TABLE `hub_group` (
    `group_hash_key` BINARY(16) NOT NULL COMMENT 'MD5-хеш от номера группы',
    `load_date` DATETIME NOT NULL COMMENT 'Дата и время загрузки записи в ХД',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `group_name` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Бизнес-ключ: номер учебной группы',
    PRIMARY KEY (`group_hash_key`)
) ENGINE=InnoDB COMMENT='Хаб: Академические учебные группы';

-- Хаб дисциплин
CREATE TABLE `hub_discipline` (
    `discipline_hash_key` BINARY(16) NOT NULL COMMENT 'MD5-хеш от кода дисциплины',
    `load_date` DATETIME NOT NULL COMMENT 'Дата и время загрузки записи в ХД',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `discipline_code` VARCHAR(30) NOT NULL UNIQUE COMMENT 'Бизнес-ключ: код дисциплины в каталоге',
    PRIMARY KEY (`discipline_hash_key`)
) ENGINE=InnoDB COMMENT='Хаб: Каталог учебных дисциплин';

-- Хаб преподавателей
CREATE TABLE `hub_teacher` (
    `teacher_hash_key` BINARY(16) NOT NULL COMMENT 'MD5-хеш от табельного номера',
    `load_date` DATETIME NOT NULL COMMENT 'Дата и время загрузки записи в ХД',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `personnel_number` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Бизнес-ключ: табельный номер',
    PRIMARY KEY (`teacher_hash_key`)
) ENGINE=InnoDB COMMENT='Хаб: Преподавательский состав';

-- =============================================================================
-- 2. ТАБЛИЦЫ-ССЫЛКИ (LINKS) — СВЯЗИ И ТРАНЗАКЦИИ
-- =============================================================================

-- Ссылка: Закрепление специальности за кафедрой
CREATE TABLE `lnk_department_specialty` (
    `dept_spec_hash_key` BINARY(16) NOT NULL COMMENT 'MD5-хеш композитного ключа связи',
    `load_date` DATETIME NOT NULL COMMENT 'Дата и время загрузки связи',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `department_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_department',
    `specialty_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_specialty',
    PRIMARY KEY (`dept_spec_hash_key`),
    CONSTRAINT `fk_lnk_ds_dept` FOREIGN KEY (`department_hash_key`) REFERENCES `hub_department` (`department_hash_key`),
    CONSTRAINT `fk_lnk_ds_spec` FOREIGN KEY (`specialty_hash_key`) REFERENCES `hub_specialty` (`specialty_hash_key`)
) ENGINE=InnoDB COMMENT='Ссылка: Закрепление специальности за кафедрой';

-- Ссылка: Привязка учебной группы к специальности
CREATE TABLE `lnk_specialty_group` (
    `spec_group_hash_key` BINARY(16) NOT NULL COMMENT 'MD5-хеш композитного ключа связи',
    `load_date` DATETIME NOT NULL COMMENT 'Дата и время загрузки связи',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `specialty_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_specialty',
    `group_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_group',
    PRIMARY KEY (`spec_group_hash_key`),
    CONSTRAINT `fk_lnk_sg_spec` FOREIGN KEY (`specialty_hash_key`) REFERENCES `hub_specialty` (`specialty_hash_key`),
    CONSTRAINT `fk_lnk_sg_grp` FOREIGN KEY (`group_hash_key`) REFERENCES `hub_group` (`group_hash_key`)
) ENGINE=InnoDB COMMENT='Ссылка: Принадлежность группы к специальности';

-- Ссылка: Учебный план (Специальность <-> Дисциплина)
CREATE TABLE `lnk_curriculum_plan` (
    `plan_hash_key` BINARY(16) NOT NULL COMMENT 'MD5-хеш композитного ключа учебного плана',
    `load_date` DATETIME NOT NULL COMMENT 'Дата и время загрузки связи',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `specialty_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_specialty',
    `discipline_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_discipline',
    PRIMARY KEY (`plan_hash_key`),
    CONSTRAINT `fk_lnk_cp_spec` FOREIGN KEY (`specialty_hash_key`) REFERENCES `hub_specialty` (`specialty_hash_key`),
    CONSTRAINT `fk_lnk_cp_disc` FOREIGN KEY (`discipline_hash_key`) REFERENCES `hub_discipline` (`discipline_hash_key`)
) ENGINE=InnoDB COMMENT='Ссылка: Позиция учебного плана специальности';

-- Ссылка: Расписание аудиторных занятий (Группа <-> Дисциплина <-> Преподаватель)
CREATE TABLE `lnk_schedule_event` (
    `schedule_hash_key` BINARY(16) NOT NULL COMMENT 'MD5-хеш факта занятия в сетке',
    `load_date` DATETIME NOT NULL COMMENT 'Дата и время загрузки связи',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `group_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_group',
    `discipline_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_discipline',
    `teacher_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_teacher',
    PRIMARY KEY (`schedule_hash_key`),
    CONSTRAINT `fk_lnk_sch_grp` FOREIGN KEY (`group_hash_key`) REFERENCES `hub_group` (`group_hash_key`),
    CONSTRAINT `fk_lnk_sch_disc` FOREIGN KEY (`discipline_hash_key`) REFERENCES `hub_discipline` (`discipline_hash_key`),
    CONSTRAINT `fk_lnk_sch_teach` FOREIGN KEY (`teacher_hash_key`) REFERENCES `hub_teacher` (`teacher_hash_key`)
) ENGINE=InnoDB COMMENT='Ссылка: Аудиторное занятие в расписании';

-- =============================================================================
-- 3. ТАБЛИЦЫ-САТЕЛЛИТЫ (SATELLITES) — ОПИСАТЕЛЬНЫЙ КОНТЕКСТ И ИСТОРИЯ
-- =============================================================================

-- Сателлит кафедры
CREATE TABLE `sat_department` (
    `department_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_department',
    `load_date` DATETIME NOT NULL COMMENT 'Дата загрузки версии атрибутов',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `department_name` VARCHAR(200) NOT NULL COMMENT 'Полное наименование кафедры',
    `created_at` DATETIME NOT NULL COMMENT 'Время создания в источнике',
    PRIMARY KEY (`department_hash_key`, `load_date`),
    CONSTRAINT `fk_sat_dept` FOREIGN KEY (`department_hash_key`) REFERENCES `hub_department` (`department_hash_key`)
) ENGINE=InnoDB COMMENT='Сателлит: Контекст кафедры';

-- Сателлит специальности
CREATE TABLE `sat_specialty` (
    `specialty_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_specialty',
    `load_date` DATETIME NOT NULL COMMENT 'Дата загрузки версии атрибутов',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `specialty_name` VARCHAR(200) NOT NULL COMMENT 'Наименование специальности',
    `created_at` DATETIME NOT NULL COMMENT 'Время создания в источнике',
    PRIMARY KEY (`specialty_hash_key`, `load_date`),
    CONSTRAINT `fk_sat_spec` FOREIGN KEY (`specialty_hash_key`) REFERENCES `hub_specialty` (`specialty_hash_key`)
) ENGINE=InnoDB COMMENT='Сателлит: Контекст направления подготовки';

-- Сателлит академической группы
CREATE TABLE `sat_group` (
    `group_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_group',
    `load_date` DATETIME NOT NULL COMMENT 'Дата загрузки версии атрибутов',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `admission_year` SMALLINT NOT NULL COMMENT 'Год набора',
    `created_at` DATETIME NOT NULL COMMENT 'Время создания в источнике',
    PRIMARY KEY (`group_hash_key`, `load_date`),
    CONSTRAINT `fk_sat_grp` FOREIGN KEY (`group_hash_key`) REFERENCES `hub_group` (`group_hash_key`)
) ENGINE=InnoDB COMMENT='Сателлит: Контекст учебной группы';

-- Сателлит дисциплины
CREATE TABLE `sat_discipline` (
    `discipline_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_discipline',
    `load_date` DATETIME NOT NULL COMMENT 'Дата загрузки версии атрибутов',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `title` VARCHAR(200) NOT NULL COMMENT 'Наименование дисциплины',
    `created_at` DATETIME NOT NULL COMMENT 'Время создания в источнике',
    PRIMARY KEY (`discipline_hash_key`, `load_date`),
    CONSTRAINT `fk_sat_disc` FOREIGN KEY (`discipline_hash_key`) REFERENCES `hub_discipline` (`discipline_hash_key`)
) ENGINE=InnoDB COMMENT='Сателлит: Контекст дисциплины';

-- Сателлит преподавателя
CREATE TABLE `sat_teacher` (
    `teacher_hash_key` BINARY(16) NOT NULL COMMENT 'FK на hub_teacher',
    `load_date` DATETIME NOT NULL COMMENT 'Дата загрузки версии атрибутов',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `full_name` VARCHAR(150) NOT NULL COMMENT 'ФИО преподавателя',
    `academic_rank` VARCHAR(100) NOT NULL COMMENT 'Звание и степень',
    `created_at` DATETIME NOT NULL COMMENT 'Время создания в источнике',
    PRIMARY KEY (`teacher_hash_key`, `load_date`),
    CONSTRAINT `fk_sat_teach` FOREIGN KEY (`teacher_hash_key`) REFERENCES `hub_teacher` (`teacher_hash_key`)
) ENGINE=InnoDB COMMENT='Сателлит: Контекст преподавателя';

-- Сателлит учебного плана (к lnk_curriculum_plan)
CREATE TABLE `sat_curriculum_plan` (
    `plan_hash_key` BINARY(16) NOT NULL COMMENT 'FK на lnk_curriculum_plan',
    `load_date` DATETIME NOT NULL COMMENT 'Дата загрузки версии атрибутов',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `semester_number` TINYINT NOT NULL COMMENT 'Номер семестра',
    `control_type` VARCHAR(50) NOT NULL COMMENT 'Форма контроля',
    `lecture_hours` SMALLINT NOT NULL DEFAULT 0 COMMENT 'Лекционные часы',
    `lab_hours` SMALLINT NOT NULL DEFAULT 0 COMMENT 'Лабораторные часы',
    `practice_hours` SMALLINT NOT NULL DEFAULT 0 COMMENT 'Практические часы',
    `total_hours` SMALLINT NOT NULL COMMENT 'Итого академических часов',
    `created_at` DATETIME NOT NULL COMMENT 'Время создания записи',
    PRIMARY KEY (`plan_hash_key`, `load_date`),
    CONSTRAINT `fk_sat_cp` FOREIGN KEY (`plan_hash_key`) REFERENCES `lnk_curriculum_plan` (`plan_hash_key`)
) ENGINE=InnoDB COMMENT='Сателлит: Параметры нагрузки по дисциплине';

-- Сателлит расписания занятий (к lnk_schedule_event)
CREATE TABLE `sat_schedule_event` (
    `schedule_hash_key` BINARY(16) NOT NULL COMMENT 'FK на lnk_schedule_event',
    `load_date` DATETIME NOT NULL COMMENT 'Дата загрузки версии атрибутов',
    `record_source` VARCHAR(100) NOT NULL COMMENT 'Система-источник данных',
    `day_of_week` TINYINT NOT NULL COMMENT 'День недели (1-6)',
    `lesson_pair` TINYINT NOT NULL COMMENT 'Номер пары (1-7)',
    `lesson_type` VARCHAR(50) NOT NULL COMMENT 'Тип пары',
    `classroom` VARCHAR(20) NOT NULL COMMENT 'Номер аудитории',
    `created_at` DATETIME NOT NULL COMMENT 'Время создания записи',
    PRIMARY KEY (`schedule_hash_key`, `load_date`),
    CONSTRAINT `fk_sat_sch` FOREIGN KEY (`schedule_hash_key`) REFERENCES `lnk_schedule_event` (`schedule_hash_key`)
) ENGINE=InnoDB COMMENT='Сателлит: Параметры аудиторного занятия';

-- =============================================================================
-- 4. СОЗДАНИЕ АНАЛИТИЧЕСКОЙ ВИТРИНЫ ДАННЫХ (DATA MART VIEW)
-- =============================================================================

CREATE OR REPLACE VIEW `v_mart_faculty_schedule` AS
SELECT 
    hg.`group_name` AS `Группа`,
    hs.`specialty_code` AS `Код спец.`,
    ss.`specialty_name` AS `Специальность`,
    hd.`department_code` AS `Кафедра`,
    hdis.`discipline_code` AS `Код дисц.`,
    sdis.`title` AS `Дисциплина`,
    scp.`semester_number` AS `Сем.`,
    scp.`control_type` AS `Контроль`,
    scp.`total_hours` AS `Часов`,
    st.`full_name` AS `Преподаватель`,
    st.`academic_rank` AS `Звание`,
    CASE sse.`day_of_week`
        WHEN 1 THEN 'Пн'
        WHEN 2 THEN 'Вт'
        WHEN 3 THEN 'Ср'
        WHEN 4 THEN 'Чт'
        WHEN 5 THEN 'Пт'
        WHEN 6 THEN 'Сб'
        ELSE 'Н/Д'
    END AS `День`,
    sse.`lesson_pair` AS `Пара`,
    sse.`lesson_type` AS `Вид`,
    sse.`classroom` AS `Ауд.`
FROM `lnk_schedule_event` lse
JOIN `hub_group` hg ON lse.`group_hash_key` = hg.`group_hash_key`
JOIN `hub_discipline` hdis ON lse.`discipline_hash_key` = hdis.`discipline_hash_key`
JOIN `sat_discipline` sdis ON hdis.`discipline_hash_key` = sdis.`discipline_hash_key`
JOIN `hub_teacher` ht ON lse.`teacher_hash_key` = ht.`teacher_hash_key`
JOIN `sat_teacher` st ON ht.`teacher_hash_key` = st.`teacher_hash_key`
JOIN `sat_schedule_event` sse ON lse.`schedule_hash_key` = sse.`schedule_hash_key`
LEFT JOIN `lnk_specialty_group` lsg ON hg.`group_hash_key` = lsg.`group_hash_key`
LEFT JOIN `hub_specialty` hs ON lsg.`specialty_hash_key` = hs.`specialty_hash_key`
LEFT JOIN `sat_specialty` ss ON hs.`specialty_hash_key` = ss.`specialty_hash_key`
LEFT JOIN `lnk_department_specialty` lds ON hs.`specialty_hash_key` = lds.`specialty_hash_key`
LEFT JOIN `hub_department` hd ON lds.`department_hash_key` = hd.`department_hash_key`
LEFT JOIN `lnk_curriculum_plan` lcp ON hs.`specialty_hash_key` = lcp.`specialty_hash_key` AND hdis.`discipline_hash_key` = lcp.`discipline_hash_key`
LEFT JOIN `sat_curriculum_plan` scp ON lcp.`plan_hash_key` = scp.`plan_hash_key`;

-- =============================================================================
-- 5. ЗАПОЛНЕНИЕ ТЕСТОВЫМ НАБОРОМ ДАННЫХ (ГРУППА 1ИИС)
-- =============================================================================

-- Загрузка Хабов
INSERT INTO `hub_department` VALUES
(UNHEX(MD5('ИУ-5')), NOW(), '1С:Университет', 'ИУ-5'),
(UNHEX(MD5('ИУ-6')), NOW(), '1С:Университет', 'ИУ-6');

INSERT INTO `hub_specialty` VALUES
(UNHEX(MD5('09.03.01')), NOW(), '1С:Университет', '09.03.01'),
(UNHEX(MD5('09.03.04')), NOW(), '1С:Университет', '09.03.04');

INSERT INTO `hub_group` VALUES
(UNHEX(MD5('1ИИС')), NOW(), '1С:Университет', '1ИИС'),
(UNHEX(MD5('2ИИС')), NOW(), '1С:Университет', '2ИИС');

INSERT INTO `hub_discipline` VALUES
(UNHEX(MD5('DISC-DWH')), NOW(), '1С:Университет', 'DISC-DWH'),
(UNHEX(MD5('DISC-OS')),  NOW(), '1С:Университет', 'DISC-OS');

INSERT INTO `hub_teacher` VALUES
(UNHEX(MD5('T-10492')), NOW(), '1С:Зарплата_Кадры', 'T-10492'),
(UNHEX(MD5('T-10518')), NOW(), '1С:Зарплата_Кадры', 'T-10518');

-- Загрузка Ссылок
INSERT INTO `lnk_department_specialty` VALUES
(UNHEX(MD5('ИУ-5|09.03.01')), NOW(), '1С:Университет', UNHEX(MD5('ИУ-5')), UNHEX(MD5('09.03.01'))),
(UNHEX(MD5('ИУ-6|09.03.04')), NOW(), '1С:Университет', UNHEX(MD5('ИУ-6')), UNHEX(MD5('09.03.04')));

INSERT INTO `lnk_specialty_group` VALUES
(UNHEX(MD5('09.03.01|1ИИС')), NOW(), '1С:Университет', UNHEX(MD5('09.03.01')), UNHEX(MD5('1ИИС'))),
(UNHEX(MD5('09.03.01|2ИИС')), NOW(), '1С:Университет', UNHEX(MD5('09.03.01')), UNHEX(MD5('2ИИС')));

INSERT INTO `lnk_curriculum_plan` VALUES
(UNHEX(MD5('09.03.01|DISC-DWH')), NOW(), '1С:Университет', UNHEX(MD5('09.03.01')), UNHEX(MD5('DISC-DWH'))),
(UNHEX(MD5('09.03.01|DISC-OS')),  NOW(), '1С:Университет', UNHEX(MD5('09.03.01')), UNHEX(MD5('DISC-OS')));

INSERT INTO `lnk_schedule_event` VALUES
(UNHEX(MD5('1ИИС|DISC-DWH|T-10492|1|1')), NOW(), 'Факультет_Деканат', UNHEX(MD5('1ИИС')), UNHEX(MD5('DISC-DWH')), UNHEX(MD5('T-10492'))),
(UNHEX(MD5('1ИИС|DISC-OS|T-10518|1|2')),  NOW(), 'Факультет_Деканат', UNHEX(MD5('1ИИС')), UNHEX(MD5('DISC-OS')),  UNHEX(MD5('T-10518')));

-- Загрузка Сателлитов
INSERT INTO `sat_department` VALUES
(UNHEX(MD5('ИУ-5')), NOW(), '1С:Университет', 'Системы обработки информации и управления', NOW()),
(UNHEX(MD5('ИУ-6')), NOW(), '1С:Университет', 'Компьютерные системы и сети', NOW());

INSERT INTO `sat_specialty` VALUES
(UNHEX(MD5('09.03.01')), NOW(), '1С:Университет', 'Информатика и вычислительная техника', NOW()),
(UNHEX(MD5('09.03.04')), NOW(), '1С:Университет', 'Программная инженерия', NOW());

INSERT INTO `sat_group` VALUES
(UNHEX(MD5('1ИИС')), NOW(), '1С:Университет', 2023, NOW()),
(UNHEX(MD5('2ИИС')), NOW(), '1С:Университет', 2023, NOW());

INSERT INTO `sat_discipline` VALUES
(UNHEX(MD5('DISC-DWH')), NOW(), '1С:Университет', 'Хранилища данных', NOW()),
(UNHEX(MD5('DISC-OS')),  NOW(), '1С:Университет', 'Операционные системы', NOW());

INSERT INTO `sat_teacher` VALUES
(UNHEX(MD5('T-10492')), NOW(), '1С:Зарплата_Кадры', 'Сергеев Виктор Николаевич', 'Доцент, к.т.н.', NOW()),
(UNHEX(MD5('T-10518')), NOW(), '1С:Зарплата_Кадры', 'Николаева Ольга Дмитриевна', 'Профессор, д.т.н.', NOW());

INSERT INTO `sat_curriculum_plan` VALUES
(UNHEX(MD5('09.03.01|DISC-DWH')), NOW(), '1С:Университет', 5, 'Экзамен', 36, 36, 18, 90, NOW()),
(UNHEX(MD5('09.03.01|DISC-OS')),  NOW(), '1С:Университет', 5, 'Зачет',   36, 18, 18, 72, NOW());

INSERT INTO `sat_schedule_event` VALUES
(UNHEX(MD5('1ИИС|DISC-DWH|T-10492|1|1')), NOW(), 'Факультет_Деканат', 1, 1, 'Лекция', 'А-401', NOW()),
(UNHEX(MD5('1ИИС|DISC-OS|T-10518|1|2')),  NOW(), 'Факультет_Деканат', 1, 2, 'Лабораторная', 'В-210', NOW());
