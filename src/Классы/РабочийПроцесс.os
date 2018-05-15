Перем Процесс_Ид;			// process
Перем Процесс_АдресСервера;	// host
Перем Процесс_ПортСервера;	// port
Перем Процесс_Параметры;
Перем Процесс_Лицензии;

Перем Кластер_Агент;
Перем Кластер_Владелец;
Перем Процесс_Соединения;

Перем ПараметрыОбъекта;

Перем ПериодОбновления;
Перем МоментАктуальности;

Перем Лог;

// Конструктор
//   
// Параметры:
//   АгентКластера			- АгентКластера	- ссылка на родительский объект агента кластера
//   Кластер				- Кластера		- ссылка на родительский объект кластера
//   Ид						- Строка		- идентификатор рабочего процесса
//
Процедура ПриСозданииОбъекта(АгентКластера, Кластер, Ид)

	Если НЕ ЗначениеЗаполнено(Ид) Тогда
		Возврат;
	КонецЕсли;

	Кластер_Агент = АгентКластера;
	Кластер_Владелец = Кластер;
	
	Процесс_Ид = Ид;

	ПараметрыОбъекта = Новый ПараметрыОбъекта("process");

	ПериодОбновления = 60000;
	МоментАктуальности = 0;
	
	Процесс_Соединения		= Новый Соединения(Кластер_Агент, Кластер_Владелец, ЭтотОбъект);
	Процесс_Лицензии		= Новый ОбъектыКластера(ЭтотОбъект);

КонецПроцедуры // ПриСозданииОбъекта()

// Процедура получает данные от сервиса администрирования кластера 1С
// и сохраняет в локальных переменных
//   
// Параметры:
//   ОбновитьПринудительно 		- Булево	- Истина - принудительно обновить данные (вызов RAC)
//											- Ложь - данные будут получены если истекло время актуальности
//													или данные не были получены ранее
//   
Процедура ОбновитьДанные(ОбновитьПринудительно = Ложь) Экспорт

	Если Служебный.ТребуетсяОбновление(Процесс_Параметры,
			МоментАктуальности, ПериодОбновления, ОбновитьПринудительно) Тогда
		ОбновитьДанныеПроцесса();
	КонецЕсли;

	Если Служебный.ТребуетсяОбновление(Процесс_Лицензии,
			МоментАктуальности, ПериодОбновления, ОбновитьПринудительно) Тогда
		ОбновитьДанныеЛицензий();
	КонецЕсли;

	МоментАктуальности = ТекущаяУниверсальнаяДатаВМиллисекундах();

КонецПроцедуры // ОбновитьДанные()

// Процедура получает данные рабочего процесса от сервиса администрирования кластера 1С
// и сохраняет в локальных переменных
//   
Процедура ОбновитьДанныеПроцесса() Экспорт

	ПараметрыЗапуска = Новый Массив();
	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаПодключения());

	ПараметрыЗапуска.Добавить("process");
	ПараметрыЗапуска.Добавить("info");

	ПараметрыЗапуска.Добавить(СтрШаблон("--process=%1", Процесс_Ид));

	ПараметрыЗапуска.Добавить(СтрШаблон("--cluster=%1", Кластер_Владелец.Ид()));
	ПараметрыЗапуска.Добавить(Кластер_Владелец.СтрокаАвторизации());

	Кластер_Агент.ВыполнитьКоманду(ПараметрыЗапуска);
	
	МассивРезультатов = Кластер_Агент.ВыводКоманды();

	Если МассивРезультатов.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;
	
	ТекОписание = МассивРезультатов[0];

	Процесс_АдресСервера = ТекОписание.Получить("host");
	Процесс_ПортСервера = ТекОписание.Получить("port");

	СтруктураПараметров = ПараметрыОбъекта();

	Процесс_Параметры = Новый Соответствие();

	Для Каждого ТекЭлемент Из СтруктураПараметров Цикл
		ЗначениеПараметра = Служебный.ПолучитьЗначениеИзСтруктуры(ТекОписание,
																  ТекЭлемент.Значение.ИмяПоляРАК,
																  ТекЭлемент.Значение.ЗначениеПоУмолчанию); 
		Процесс_Параметры.Вставить(ТекЭлемент.Ключ, ЗначениеПараметра);
	КонецЦикла;

КонецПроцедуры // ОбновитьДанныеПроцесса()

// Процедура получает данные лицензий, выданных рабочим процессом
// и сохраняет в локальных переменных
//   
Процедура ОбновитьДанныеЛицензий() Экспорт

	ПараметрыЗапуска = Новый Массив();
	ПараметрыЗапуска.Добавить(Кластер_Агент.СтрокаПодключения());

	ПараметрыЗапуска.Добавить("process");
	ПараметрыЗапуска.Добавить("info");

	ПараметрыЗапуска.Добавить("--licenses");

	ПараметрыЗапуска.Добавить(СтрШаблон("--process=%1", Процесс_Ид));

	ПараметрыЗапуска.Добавить(СтрШаблон("--cluster=%1", Кластер_Владелец.Ид()));
	ПараметрыЗапуска.Добавить(Кластер_Владелец.СтрокаАвторизации());

	Кластер_Агент.ВыполнитьКоманду(ПараметрыЗапуска);
	
	Процесс_Лицензии.Заполнить(Кластер_Агент.ВыводКоманды());

КонецПроцедуры // ОбновитьДанныеЛицензий()

// Функция возвращает коллекцию параметров объекта
//   
// Параметры:
//   ИмяПоляКлюча 		- Строка	- имя поля, значение которого будет использовано
//									  в качестве ключа возвращаемого соответствия
//   
// Возвращаемое значение:
//	Соответствие - коллекция параметров объекта, для получения/изменения значений
//
Функция ПараметрыОбъекта(ИмяПоляКлюча = "ИмяПараметра") Экспорт

	Возврат ПараметрыОбъекта.Получить(ИмяПоляКлюча);

КонецФункции // ПараметрыОбъекта()

// Функция возвращает идентификатор рабочего процесса 1С
//   
// Возвращаемое значение:
//	Строка - идентификатор рабочего процесса 1С
//
Функция Ид() Экспорт

	Возврат Процесс_Ид;

КонецФункции // Ид()

// Функция возвращает адрес сервера рабочего процесса 1С
//   
// Возвращаемое значение:
//	Строка - адрес сервера рабочего процесса 1С
//
Функция АдресСервера() Экспорт
	
	Если Служебный.ТребуетсяОбновление(Процесс_АдресСервера, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Истина);
	КонецЕсли;

	Возврат Процесс_АдресСервера;
		
КонецФункции // АдресСервера()
	
// Функция возвращает порт рабочего процесса 1С
//   
// Возвращаемое значение:
//	Строка - порт рабочего процесса 1С
//
Функция ПортСервера() Экспорт
	
	Если Служебный.ТребуетсяОбновление(Процесс_ПортСервера, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Истина);
	КонецЕсли;

	Возврат Процесс_ПортСервера;
		
КонецФункции // ПортСервера()
	
// Функция возвращает значение параметра рабочего процесса 1С
//   
// Параметры:
//   ИмяПоля			 	- Строка		- Имя параметра рабочего процесса
//   ОбновитьПринудительно 	- Булево		- Истина - обновить список (вызов RAC)
//
// Возвращаемое значение:
//	Произвольный - значение параметра рабочего процесса 1С
//
Функция Получить(ИмяПоля, ОбновитьПринудительно = Ложь) Экспорт
	
	ОбновитьДанные(ОбновитьПринудительно);

	Если НЕ Найти(ВРег("Ид, process"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Процесс_Ид;
	ИначеЕсли НЕ Найти(ВРег("АдресСервера, host"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Процесс_АдресСервера;
	ИначеЕсли НЕ Найти(ВРег("ПортСервера, port"), ВРег(ИмяПоля)) = 0 Тогда
		Возврат Процесс_ПортСервера;
	КонецЕсли;
	
	ЗначениеПоля = Процесс_Параметры.Получить(ИмяПоля);

	Если ЗначениеПоля = Неопределено Тогда
		
		ОписаниеПараметра = ПараметрыОбъекта("ИмяПоляРАК").Получить(ИмяПоля);

		Если НЕ ОписаниеПараметра = Неопределено Тогда
			ЗначениеПоля = Процесс_Параметры.Получить(ОписаниеПараметра["ИмяПараметра"]);
		КонецЕсли;
	КонецЕсли;

	Возврат ЗначениеПоля;
		
КонецФункции // Получить()
	
// Функция возвращает список соединений рабочего процесса 1С
//   
// Возвращаемое значение:
//	Соединения - список соединений рабочего процесса 1С
//
Функция Соединения() Экспорт
	
	Возврат Процесс_Соединения;
	
КонецФункции // Соединения()
	
// Функция возвращает список лицензий, выданных рабочим процессом 1С
//   
// Возвращаемое значение:
//	ОбъектыКластера - список лицензий, выданных рабочим процессом 1С
//
Функция Лицензии() Экспорт
	
	Если Служебный.ТребуетсяОбновление(Процесс_Лицензии, МоментАктуальности, ПериодОбновления) Тогда
		ОбновитьДанные(Истина);
	КонецЕсли;

	Возврат Процесс_Лицензии;
	
КонецФункции // Лицензии()
	
Лог = Логирование.ПолучитьЛог("ktb.lib.irac");
