-- ЧАСТЬ 1. ПРОЕКТИРОВАНИЕ ХРАНИЛИЩА ДАННЫХ В 3-Й НОРМАЛЬНОЙ ФОРМЕ (3NF)
CREATE DATABASE IF NOT EXISTS `faculty_curriculum_3nf`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `faculty_curriculum_3nf`;

-- 1. Таблица кафедр
CREATE TABLE `departments` (
    `department_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный ID кафедры',
    `department_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Шифр кафедры (бизнес-ключ)',
    `department_name` VARCHAR(200) NOT NULL COMMENT 'Полное название кафедры',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления'
) ENGINE=InnoDB COMMENT='Справочник кафедр факультета (3NF)';

-- 2. Таблица специальностей
CREATE TABLE `specialties` (
    `specialty_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный ID специальности',
    `department_id` INT NOT NULL COMMENT 'Ссылка на выпускающую кафедру',
    `specialty_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Код специальности по ФГОС (бизнес-ключ)',
    `specialty_name` VARCHAR(200) NOT NULL COMMENT 'Наименование специальности',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',
    CONSTRAINT `fk_3nf_spec_dept` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`)
) ENGINE=InnoDB COMMENT='Справочник направлений подготовки (3NF)';

-- 3. Таблица академических групп
CREATE TABLE `academic_groups` (
    `group_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный ID группы',
    `specialty_id` INT NOT NULL COMMENT 'Ссылка на специальность',
    `group_name` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Номер группы (бизнес-ключ)',
    `admission_year` SMALLINT NOT NULL COMMENT 'Год набора студентов',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',
    CONSTRAINT `fk_3nf_grp_spec` FOREIGN KEY (`specialty_id`) REFERENCES `specialties` (`specialty_id`)
) ENGINE=InnoDB COMMENT='Справочник академических групп (3NF)';

-- 4. Таблица учебных дисциплин
CREATE TABLE `disciplines` (
    `discipline_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный ID дисциплины',
    `department_id` INT NOT NULL COMMENT 'Ссылка на читающую кафедру',
    `discipline_code` VARCHAR(30) NOT NULL UNIQUE COMMENT 'Код дисциплины (бизнес-ключ)',
    `title` VARCHAR(200) NOT NULL COMMENT 'Наименование учебной дисциплины',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',
    CONSTRAINT `fk_3nf_disc_dept` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`)
) ENGINE=InnoDB COMMENT='Каталог учебных дисциплин (3NF)';

-- 5. Таблица преподавателей
CREATE TABLE `teachers` (
    `teacher_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный ID преподавателя',
    `department_id` INT NOT NULL COMMENT 'Ссылка на кафедру преподавателя',
    `personnel_number` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Табельный номер (бизнес-ключ)',
    `full_name` VARCHAR(150) NOT NULL COMMENT 'ФИО преподавателя',
    `academic_rank` VARCHAR(100) NOT NULL COMMENT 'Ученое звание и степень',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',
    CONSTRAINT `fk_3nf_teach_dept` FOREIGN KEY (`department_id`) REFERENCES `departments` (`department_id`)
) ENGINE=InnoDB COMMENT='Справочник преподавателей (3NF)';

-- 6. Таблица учебного графика и плана нагрузки
CREATE TABLE `curriculum_plans` (
    `plan_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный ID позиции учебного плана',
    `specialty_id` INT NOT NULL COMMENT 'Ссылка на специальность',
    `discipline_id` INT NOT NULL COMMENT 'Ссылка на дисциплину',
    `semester_number` TINYINT NOT NULL COMMENT 'Номер семестра (1-8)',
    `control_type` VARCHAR(50) NOT NULL COMMENT 'Форма контроля (Экзамен, Зачет, Диф.зачет)',
    `lecture_hours` SMALLINT NOT NULL DEFAULT 0 COMMENT 'Объем лекционных часов',
    `lab_hours` SMALLINT NOT NULL DEFAULT 0 COMMENT 'Объем лабораторных часов',
    `practice_hours` SMALLINT NOT NULL DEFAULT 0 COMMENT 'Объем практических часов',
    `total_hours` SMALLINT NOT NULL COMMENT 'Суммарная трудоемкость в часах',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',
    CONSTRAINT `uq_3nf_plan` UNIQUE (`specialty_id`, `discipline_id`, `semester_number`),
    CONSTRAINT `fk_3nf_plan_spec` FOREIGN KEY (`specialty_id`) REFERENCES `specialties` (`specialty_id`),
    CONSTRAINT `fk_3nf_plan_disc` FOREIGN KEY (`discipline_id`) REFERENCES `disciplines` (`discipline_id`)
) ENGINE=InnoDB COMMENT='Учебный график дисциплин (3NF)';

-- 7. Таблица сетки расписания аудиторных занятий
CREATE TABLE `schedule_events` (
    `event_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Уникальный ID занятия в сетке',
    `group_id` INT NOT NULL COMMENT 'Ссылка на академическую группу',
    `discipline_id` INT NOT NULL COMMENT 'Ссылка на дисциплину',
    `teacher_id` INT NOT NULL COMMENT 'Ссылка на преподавателя',
    `day_of_week` TINYINT NOT NULL COMMENT 'День недели (1-Пн, ..., 6-Сб)',
    `lesson_pair` TINYINT NOT NULL COMMENT 'Номер пары по порядку (1-7)',
    `lesson_type` VARCHAR(50) NOT NULL COMMENT 'Тип занятия (Лекция, Лабораторная, Семинар)',
    `classroom` VARCHAR(20) NOT NULL COMMENT 'Номер аудитории',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',
    CONSTRAINT `fk_3nf_sch_grp` FOREIGN KEY (`group_id`) REFERENCES `academic_groups` (`group_id`),
    CONSTRAINT `fk_3nf_sch_disc` FOREIGN KEY (`discipline_id`) REFERENCES `disciplines` (`discipline_id`),
    CONSTRAINT `fk_3nf_sch_teach` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`teacher_id`)
) ENGINE=InnoDB COMMENT='Сетка расписания занятий (3NF)';
