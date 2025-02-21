#Persistent
#NoEnv
#SingleInstance Force

; Початкове привітання
ShowWelcomeMessage() {
    Gui, +AlwaysOnTop +ToolWindow -Caption
    Gui, Margin, 20, 20
    Gui, Color, F5F5F5 ; Світло-сірий фон
    Gui, Font, c2E2E2E s16 Bold, Segoe UI
    Gui, Add, Text, Center, Вітаю, HRMV-Script запущено!
    Gui, Show, AutoSize Center
    Sleep, 2000
    Gui, Destroy
}
ShowWelcomeMessage()

; Універсальна функція вставки тексту
InsertText(Text) {
    Gui, Destroy
    Clipboard := Text
    Send, ^v
    Sleep, 50 ; Зменшена затримка для швидкості
    Clipboard := ""
}

#SingleInstance Force
#NoEnv

SetTimer, CheckUpdate, 86400000 ; Перевіряти оновлення раз на день (86400000 мс)
^U:: ; Гаряча клавіша Ctrl + U для ручної перевірки
CheckUpdate:
MsgBox, , Діагностика, Початок перевірки оновлень...
; Завантажуємо version.txt з Dropbox для перевірки версії
UrlDownloadToFile, https://www.dropbox.com/scl/fi/tdkeo9o3iso46a2csouof/version.txt?rlkey=9az1e2jsiiwy01vi9glhnnb6e&st=xah53ahu&dl=1, %A_ScriptDir%\version.txt
if (ErrorLevel) { ; Якщо виникла помилка завантаження
    MsgBox, 48, Помилка, Не вдалося завантажити version.txt. ErrorLevel: %ErrorLevel%. Перевірте URL або підключення до інтернету.
    FileDelete, %A_ScriptDir%\version.txt ; Видаляємо тимчасовий файл, якщо він є
    return
}

FileRead, RemoteVersion, %A_ScriptDir%\version.txt
if (RemoteVersion = "") { ; Якщо файл порожній або не зчитався
    MsgBox, 48, Помилка, Файл version.txt порожній або некоректний. Перевірте вміст на сервері.
    FileDelete, %A_ScriptDir%\version.txt
    return
}

; Логування для діагностики
FormatTime, CurrentTime,, yyyy-MM-dd HH:mm:ss
FileAppend, [%CurrentTime%] Зчитана версія з version.txt: %RemoteVersion%`n, %A_ScriptDir%\update_log.txt, UTF-8

; Очищаємо версію від зайвих пробілів і символів
RemoteVersion := Trim(RemoteVersion)
if (!RegExMatch(RemoteVersion, "^\d+\.\d+(\.\d+)?$")) { ; Перевірка формату версії (наприклад, "0.4" або "0.4.0")
    MsgBox, 48, Помилка, Версія у version.txt має неправильний формат. Очікується формат X.Y або X.Y.Z (наприклад, 0.4). Зміст: %RemoteVersion%
    FileDelete, %A_ScriptDir%\version.txt
    return
}

LocalVersion := "0.3" ; Поточна версія твого скрипта (заміни на актуальну)
FileAppend, [%CurrentTime%] Локальна версія: %LocalVersion%`n, %A_ScriptDir%\update_log.txt, UTF-8

; Порівнюємо версії (додаємо числове порівняння для коректності)
VersionCompare(version1, version2) {
    Loop, Parse, version1, .
        v1%A_Index% := A_LoopField
    Loop, Parse, version2, .
        v2%A_Index% := A_LoopField
    Loop, 3
    {
        if (v1%A_Index% > v2%A_Index%)
            return 1
        if (v1%A_Index% < v2%A_Index%)
            return -1
    }
    return 0
}

if (VersionCompare(RemoteVersion, LocalVersion) > 0) {
    MsgBox, 36, Оновлення, Доступна нова версія %RemoteVersion% (з сайту). Оновити зараз?, 10
    IfMsgBox, Yes
    {
        MsgBox, , Діагностика, Початок завантаження оновленого скрипта...
        ; Завантажуємо оновлений скрипт з Dropbox
        UrlDownloadToFile, https://www.dropbox.com/scl/fi/fj5rvi0e2hxmvy4gh4cc2/HRMV.ahk?rlkey=o19k95jtupztlbmpbxix2r32t&st=1hjg5akd&dl=1, %A_ScriptDir%\new_version.ahk
        if (ErrorLevel) {
            MsgBox, 48, Помилка, Не вдалося завантажити оновлення. ErrorLevel: %ErrorLevel%
            FileDelete, %A_ScriptDir%\new_version.ahk
            FileDelete, %A_ScriptDir%\version.txt
            return
        }

        ; Створюємо резервну копію поточного файла
        FileCopy, %A_ScriptDir%\%A_ScriptName%, %A_ScriptDir%\backup_%A_ScriptName%, 1
        if (ErrorLevel) {
            MsgBox, 48, Помилка, Не вдалося створити резервну копію. ErrorLevel: %ErrorLevel%
            FileDelete, %A_ScriptDir%\new_version.ahk
            FileDelete, %A_ScriptDir%\version.txt
            return
        }

        ; Замінюємо поточний файл новою версією
        FileMove, %A_ScriptDir%\new_version.ahk, %A_ScriptDir%\%A_ScriptName%, 1
        if (ErrorLevel) {
            MsgBox, 48, Помилка, Не вдалося оновити файл. ErrorLevel: %ErrorLevel%
            FileDelete, %A_ScriptDir%\version.txt
            return
        }

        ; Видаляємо тимчасові файли
        FileDelete, %A_ScriptDir%\version.txt

        ; Перезапускаємо скрипт із новою версією
        MsgBox, , Діагностика, Оновлення завершено, перезапуск скрипта...
        Run, %A_ScriptFullPath%
        ExitApp ; Закриваємо поточну версію
    }
    else
    {
        FileDelete, %A_ScriptDir%\new_version.ahk ; Видаляємо тимчасовий файл, якщо користувач відмовився
        FileDelete, %A_ScriptDir%\version.txt ; Видаляємо version.txt, щоб уникнути використання застарілої версії
    }
} else {
    MsgBox, 64, Оновлення, У вас остання версія %LocalVersion%!
    FileDelete, %A_ScriptDir%\version.txt ; Видаляємо version.txt, щоб завжди перевіряти версію з сервера
}

return

; Налаштування таймера для нагадування о 14:00
SetTimer, CheckTime, 60000
return

CheckTime:
FormatTime, CurrentTime,, HHmm
if (CurrentTime = "1354") {
    Gui, Reminder:Destroy
    Gui, Reminder:+AlwaysOnTop +ToolWindow -Caption
    Gui, Reminder:Margin, 20, 20
    Gui, Reminder:Color, F5F5F5
    Gui, Reminder:Font, c2E2E2E s16 Bold, Segoe UI
    Gui, Reminder:Add, Text, Center, Прописати людей і адміністраторів
    Gui, Reminder:Show, AutoSize Center
    Sleep, 5000
    Gui, Reminder:Destroy
}
return


; Підказки (Alt + 1)
!1::
Gui, Destroy ; Закриваємо будь-яке попереднє GUI
Gui, +AlwaysOnTop -SysMenu +ToolWindow +Owner ; Завжди зверху, без системного меню
Gui, Margin, 15, 15
Gui, Color, 2A2F3B ; Темно-синій фон
Gui, Font, cFFFFFF s14 Bold, Segoe UI
Gui, Add, Text, x15 y15 w370 Center, Підказки:`n
Gui, Font, cDDE4E8 s10 Normal, Segoe UI
Gui, Add, Text, x15 y50 w370, Alt + 1 - Меню підказок`nAlt + 2 - Коментар Zoho CRM`nAlt + 3 - Меню скриптів`nAlt + 4 - ЧаПи Казахстан`nAlt + 5 - ЧаПи Україна`nAlt + 8 - Редагування скриптів`nCtrl + 1 - Пріоритет + замітка`nCtrl + 2 - Меню прописів`nCtrl + X - Контекстне меню`nWin + W - Zoho CRM`nWin + O - Орбіта
Gui, Font, cA0A0A0 s9 Italic, Segoe UI
Gui, Add, Text, x15 y290 w370 Center, HRMV v3.0
Gui, Show, w400 h330 Center, Підказки
return

; Обробники для закриття через Esc або хрестик
GuiEscapep:
GuiClosep:
Gui, Destroy ; Закриваємо GUI при натисканні Esc або закритті
return

!2::
Gui, Destroy
Gui, +AlwaysOnTop -SysMenu +ToolWindow
Gui, Margin, 10, 10 ; Залишаємо відступи
Gui, Color, 2A2F3B ; Темно-синій фон
Gui, Font, cF5F5F5 s12 Bold, Segoe UI ; Кремовий текст для заголовка
Gui, Add, Text, Center, Оберіть причину закриття заявки:`n`n
Gui, Font, cF5F5F5 s10 Bold, Segoe UI ; М’якший шрифт для кнопок

; Масив причин (залишаємо без змін)
Reasons := {}
Reasons["SpecificReason"] := "Кандидату не підходить специфіка роботи"
Reasons["ActualSearch"] := "Кандидату не актуальний пошук або не залишав відгук"
Reasons["SilentReason"] := "Ігнорує, на дзвінки не відповідає"
Reasons["NoTech"] := "В кандидата немає техніки"
Reasons["WrongNumber"] := "Номер не працює/обмежений/не існує"
Reasons["NoResponse"] := "Кандидат не відповідає"
Reasons["Inadequate"] := "Кандидат веде себе неадекватно"
Reasons["HangUp"] := "Кандидат скинув трубку та ігнорує"
Reasons["BadSchedule"] := "Кандидату не підходить жоден графік"
Reasons["Experienced"] := "Кандидат з досвідом, не цікавить"
Reasons["Tfp"] := "Кандидату 35+ років"
Reasons["EigM"] := "Кандидату 17- років"
Reasons["Pidrobitok"] := "Кандидат думав, що це підробіток"

; Кнопки з групуванням, без рамок, м’якший фон
Gui, Add, GroupBox, w700 h150 x10 y30 c808080, Робочі причини ; Світліший колір для GroupBox
Gui, Add, Button, gInsertReason vSpecificReason w320 h30 x30 y60 -Border BackgroundB0B0B0, Не підходить специфіка
Gui, Add, Button, gInsertReason vActualSearch w320 h30 x360 y60 -Border BackgroundB0B0B0, Не актуальний пошук
Gui, Add, Button, gInsertReason vBadSchedule w320 h30 x30 y100 -Border BackgroundB0B0B0, Не підходить графік
Gui, Add, Button, gInsertReason vExperienced w320 h30 x360 y100 -Border BackgroundB0B0B0, Має досвід
Gui, Add, Button, gInsertReason vPidrobitok w320 h30 x30 y140 -Border BackgroundB0B0B0, Підробіток

Gui, Add, GroupBox, w700 h150 x10 y190 c808080, Технічні/контактні причини
Gui, Add, Button, gInsertReason vSilentReason w320 h30 x30 y210 -Border BackgroundB0B0B0, Програна угода
Gui, Add, Button, gInsertReason vNoTech w320 h30 x360 y210 -Border BackgroundB0B0B0, Немає техніки
Gui, Add, Button, gInsertReason vWrongNumber w320 h30 x30 y250 -Border BackgroundB0B0B0, Не правильний номер
Gui, Add, Button, gInsertReason vNoResponse w320 h30 x360 y250 -Border BackgroundB0B0B0, Недозвон
Gui, Add, Button, gInsertReason vHangUp w320 h30 x30 y290 -Border BackgroundB0B0B0, Скинув трубку
Gui, Add, Button, gInsertReason vInadequate w320 h30 x360 y290 -Border BackgroundB0B0B0, Не адекват

Gui, Add, GroupBox, w700 h80 x10 y350 c808080, Вікові причини
Gui, Add, Button, gInsertReason vTfp w320 h40 x30 y380 -Border BackgroundB0B0B0, 35+
Gui, Add, Button, gInsertReason vEigM w320 h40 x360 y380 -Border BackgroundB0B0B0, 18-

Gui, Add, Button, gCloseGui w200 h50 x270 y450 -Border BackgroundB0B0B0, Відмінити
Gui, Show, AutoSize Center, Вибір причини
return

InsertReason:
InsertText(Reasons[A_GuiControl])
return

CloseGui:
GuiClose:
GuiEscape:
Gui, Destroy
return

; ЧаПи Казахстан (Alt + 4)
!4::
Gui, Destroy
Gui, +AlwaysOnTop -SysMenu +ToolWindow
Gui, Margin, 10, 10
Gui, Color, 2A2F3B ; Темно-синій фон
Gui, Font, cD3D3D3 s12 Bold, Segoe UI
Gui, Add, Text, Center, Виберіть запитання кандидата (Казахстан):`n`n
Gui, Font, cD3D3D3 s10 Bold, Segoe UI

KZResponses := {}
KZResponses["Legal"] := "Да, наша работа легальная, мы работаем официально и со второго месяца работы предлагаем официальное трудоустройство, по Вашему желанию, если не желаете то сможете остаться на неофициальном трудоустройстве."
KZResponses["Skokzp"] := "Конечно Вы сможете зарабатывать, главное иметь желание обучаться чему-то новому и конечно иметь желание зарабатывать."
KZResponses["Official"] := "Да, компания работает официально и со второго месяца по желанию Вы сможете устроится официально."
KZResponses["Scamer"] := "Нет, мы не мошенники, я могу Вас в этом уверить, мы как компания предоставили видео-презентацию вакансии, я отвечаю чётко на Ваши вопросы и если желаете мы можем с Вами созвонится и я Вам так-же легко отвечу на все вопросы, что будут Вас интересовать."
KZResponses["WhyDoc"] := "Документ в первую очередь нужен для того, чтобы Вы могли подтвердить свою личность и свой возраст, так-же нам нужен документ чтобы мы могли Вас внести в базу данных наших работников и могли создать для Вас все доступы к началу обучения."
KZResponses["Piramida"] := "Нет, это не пирамида, я даже не знаю где Вам удалось увидеть признаки пирамиды, возможно Вы увидели пирамиду в Премии 'Сарафан', но нет, это так-же не пирамида, а больше похоже на реферальную систему, сейчас Вам отправлю условия, чтобы Вы могли точно удостоверится в чистоте этой премии."
KZResponses["SkokSr"] := "В среднем менеджер на первый месяц зарабатывает 450-500 долларов, потому как первый месяц это адаптация и стажировка, со второго месяца уже от 800 долларов менеджер в силе зарабатывать."
KZResponses["KogOb"] := "Обучение Вы сможете начать в любой удобный для себя день, обучение проходит по графику, то есть зависимо от смены которую Вы для себя выбрали."
KZResponses["Staj"] := "Выплаты за стажировку у каждого по разному, в среднем менеджер получает за стажировку 200-250 долларов."
KZResponses["Nar"] := "Нет, мы не наркошоп, наша компания занимается развитием платформ, а именно поднятием активности на сайте, путём общения с пользователями."
KZResponses["Webcam"] := "Нет, мы не вебкам и не онлифанс, ничего подобного, наша компания работает в сфере трафика, а именно мы поднимаем активности на платформе путём общения на различную тематику в текстовых чатах, то есть не в звонках и не по видео, так-же мы ничего не продаём, то есть мы не занимаемся продажей кастомов."
KZResponses["AuVid"] := "Нет, это не видео и не звонки, наша компания работает в сфере трафика, а именно мы поднимаем активность на платформе путём общения на различную тематику в текстовых чатах, то есть не в звонках и не по видео, так-же мы ничего не продаём, то есть мы не занимаемся продажей кастомов."
KZResponses["WhyCl"] := "Клиенты не желают вести общение, они подписали клиентское соглашение с нашей компанией и получают пасивный доход, взамен клиент постоянно пополняет контент, то есть создаёт фото, аудио, видео, чтобы Аккаунт-Менеджер мог продолжать общение."
KZResponses["Oklad"] := "Нет, оклада у менеджеров нет, работа идёт на процент, 48 процентов базовых от монетизации и 20 процентов боусных."
KZResponses["Nchasov"] := "Нужно работать полный рабочий день, то есть нужно сидеть всю смену, перерывы конечно есть, Вам даётся 1 час перерыва на смену, конечно если Вам нужно отойти в туалет например или что-то перекусить то никто не будет Вас заставлять сидеть и мы никак это не проконтролируем, просто если отлучаетесь отпишите администраторы, поддерживайте коммуникацию."
KZResponses["Otluch"] := "Нет, отлучаться на долгий период времени нельзя, Вам даётся всего 1 час перерыва на смену, отлучится Вы можете на короткий период, например в туалет или быстро перекусить."
KZResponses["KogdaZp"] := "Зарплата выплачиватся с 8 по 12 число месяца, на любую банковскую карту или электронный кошелёк, как Вам будет удобно."
KZResponses["KogdaAvans"] := "Вы сможете взять аванс только после прохождения стажировки, так как первые 2 недели это только адаптация."
KZResponses["Telef"] := "Нет, с телефона или планшета работать нельзя, вся работа проходит с компьютера или ноутбука, максимум если Вы отлучились от рабочего места на перерыв, перекус и так далее то Вы можете на короткий период зайти с телефона и подрабатывать."

Gui, Add, Button, gInsertResponse vLegal w280 h30 x10 y40 +Border, Ваша работа легальная?
Gui, Add, Button, gInsertResponse vSkokzp w280 h30 x300 y40 +Border, А я смогу здесь зарабатывать?
Gui, Add, Button, gInsertResponse vOfficial w280 h30 x10 y80 +Border, Работа официальная?
Gui, Add, Button, gInsertResponse vScamer w280 h30 x300 y80 +Border, Вы не мошенник?
Gui, Add, Button, gInsertResponse vWhyDoc w280 h30 x10 y120 +Border, Зачем Вам мой документ?
Gui, Add, Button, gInsertResponse vPiramida w280 h30 x300 y120 +Border, Это пирамида?
Gui, Add, Button, gInsertResponse vSkokSr w280 h30 x10 y160 +Border, Сколько в среднем я смогу заработать?
Gui, Add, Button, gInsertResponse vKogOb w280 h30 x300 y160 +Border, Когда обучение?
Gui, Add, Button, gInsertResponse vStaj w280 h30 x10 y200 +Border, Сколько я получу за стажировку?
Gui, Add, Button, gInsertResponse vNar w280 h30 x300 y200 +Border, Это наркошоп?
Gui, Add, Button, gInsertResponse vWebcam w280 h30 x10 y240 +Border, Это вебкам или онлик?
Gui, Add, Button, gInsertResponse vAuVid w280 h30 x300 y240 +Border, Это не видео и не звонки?
Gui, Add, Button, gInsertResponse vWhyCl w280 h30 x10 y280 +Border, Почему клиенты сами не общаются?
Gui, Add, Button, gInsertResponse vOklad w280 h30 x300 y280 +Border, А есть оклад?
Gui, Add, Button, gInsertResponse vNchasov w280 h30 x10 y320 +Border, Нужно 9 часов сидеть?
Gui, Add, Button, gInsertResponse vOtluch w280 h30 x300 y320 +Border, А я смогу отлучится на 2-3 часа?
Gui, Add, Button, gInsertResponse vKogdaZp w280 h30 x10 y360 +Border, Когда выплата зп?
Gui, Add, Button, gInsertResponse vKogdaAvans w280 h30 x300 y360 +Border, Аванс можно взять?
Gui, Add, Button, gInsertResponse vTelef w280 h30 x10 y400 +Border, С телефона/планшета можно?
Gui, Add, Button, gCloseGui w280 h30 x300 y400 +Border, Відмінити
Gui, Show, AutoSize Center, ЧаПи КЗ
return

InsertResponse:
InsertText(KZResponses[A_GuiControl])
return

; ЧаПи Україна (Alt + 5)
!5::
Gui, Destroy
Gui, +AlwaysOnTop -SysMenu +ToolWindow
Gui, Margin, 10, 10
Gui, Color, 2A2F3B ; Темно-синій фон
Gui, Font, cD3D3D3 s12 Bold, Segoe UI
Gui, Add, Text, Center, Виберіть запитання кандидата (Україна):`n`n
Gui, Font, cD3D3D3 s10 Bold, Segoe UI

UAResponses := {}
UAResponses["Lgal"] := "Так, наша робота легальна, ми працюємо офіційно і з другого місяця роботи пропонуємо офіційне працевлаштування, за Вашим бажанням, якщо не бажаєте, то зможете залишитися на неофіційному працевлаштуванні."
UAResponses["Skozp"] := "Звичайно, Ви зможете заробляти, головне мати бажання навчатися чогось нового і звичайно мати бажання заробляти."
UAResponses["Oficial"] := "Так, компанія працює офіційно і з другого місяця за бажанням Ви зможете влаштуватися офіційно."
UAResponses["WhDoc"] := "Документ в першу чергу потрібен для того, щоб Ви могли підтвердити свою особистість і свій вік, так само нам потрібен документ, щоб ми могли Вас внести в базу даних наших працівників і могли створити для Вас всі доступи до початку навчання."
UAResponses["SkoSr"] := "У середньому менеджер на перший місяць заробляє 450-500 доларів, тому що перший місяць це адаптація та стажування, з другого місяця вже від 800 доларів менеджер має можливість заробляти."
UAResponses["KoOb"] := "Навчання Ви зможете розпочати у будь-який зручний для себе день, навчання проходить за графіком, тобто залежно від зміни, яку Ви для себе обрали."
UAResponses["Stag"] := "Виплати за стажування у кожного по різному, в середньому менеджер отримує за стажування 200-250 доларів."
UAResponses["Webam"] := "Ні, ми не вебкам і не онліфанс, нічого подібного, наша компанія працює в сфері трафіку, а саме ми піднімаємо активність на платформі шляхом спілкування на різну тематику в текстових чатах, тобто не в дзвінках і не відео, також ми нічого не продаємо, тобто ми не займаємось продажем кастомів."
UAResponses["WhCl"] := "Клієнти не бажають вести спілкування, вони підписали клієнтську угоду з нашою компанією і отримують пасивний дохід, натомість клієнт постійно поповнює контент, тобто створює фото, аудіо, відео, щоб Аккаунт-Менеджер міг продовжувати спілкування."
UAResponses["Okad"] := "Ні, ставки у менеджерів немає, робота йде на відсоток, 48 відсотків базових від монетизації та 20 відсотків боусних."
UAResponses["Ncasov"] := "Потрібно працювати повний робочий день, тобто потрібно сидіти всю зміну, перерви звичайно є, Вам дається 1 година перерви на зміну, звичайно якщо Вам потрібно відійти в туалет наприклад або щось перекусити, то ніхто не буде Вас змушувати сидіти і ми ніяк це не проконтролюємо, просто якщо відлучаєтеся відпишіть адміністратори, підтримуйте комунікацію."
UAResponses["Otuch"] := "Ні, відлучатися на довгий період часу не можна, Вам дається лише 1 година перерви на зміну, відлучиться Ви можете на короткий період, наприклад, у туалет або швидко перекусити."
UAResponses["KogdaZ"] := "Зарплата виплачується з 8 по 12 число місяця, на будь-яку банківську картку або електронний гаманець, як Вам буде зручно."
UAResponses["KogdaA"] := "Ви зможете взяти аванс лише після проходження стажування, оскільки перші 2 тижні це лише адаптація."
UAResponses["Teef"] := "Ні, з телефона або планшета працювати не можна, вся робота проходить з комп'ютера або ноутбука, максимум якщо Ви відлучилися від робочого місця на перерву, перекус і так далі, то Ви можете на короткий період зайти з телефону і підробляти."

Gui, Add, Button, gInseertResponse vLgal w280 h30 x10 y40 +Border, Ваша робота легальна?
Gui, Add, Button, gInseertResponse vSkozp w280 h30 x300 y40 +Border, А я зможу тут заробляти?
Gui, Add, Button, gInseertResponse vOficial w280 h30 x10 y80 +Border, Робота офіційна?
Gui, Add, Button, gInseertResponse vWhDoc w280 h30 x300 y80 +Border, Навіщо Вам мій документ?
Gui, Add, Button, gInseertResponse vSkoSr w280 h30 x10 y120 +Border, Скільки в середньому я зможу тут заробляти?
Gui, Add, Button, gInseertResponse vKoOb w280 h30 x300 y120 +Border, Коли навчання?
Gui, Add, Button, gInseertResponse vStag w280 h30 x10 y160 +Border, Скільки я отримаю за стажування?
Gui, Add, Button, gInseertResponse vWebam w280 h30 x300 y160 +Border, Це вебкам чи онлік?
Gui, Add, Button, gInseertResponse vWhCl w280 h30 x10 y200 +Border, Чому клієнти самі не спілкуються?
Gui, Add, Button, gInseertResponse vOkad w280 h30 x300 y200 +Border, Ставка є?
Gui, Add, Button, gInseertResponse vNcasov w280 h30 x10 y240 +Border, Потрібно весь час сидіти і не відходити?
Gui, Add, Button, gInseertResponse vOtuch w280 h30 x300 y240 +Border, Я зможу відлучитись на 2-3 години?
Gui, Add, Button, gInseertResponse vKogdaZ w280 h30 x10 y280 +Border, Коли виплата ЗП?
Gui, Add, Button, gInseertResponse vKogdaA w280 h30 x300 y280 +Border, Аванс можна взяти?
Gui, Add, Button, gInseertResponse vTeef w280 h30 x10 y320 +Border, З телефона/планшета можна?
Gui, Add, Button, gCloseGui w280 h30 x300 y320 +Border, Відмінити
Gui, Show, AutoSize Center, ЧаПи Україна
return

InseertResponse:
InsertText(UAResponses[A_GuiControl])
return


; Швидкі посилання
#W::Run, https://crm.zoho.eu/crm/org20098981754/tab/Potentials/custom-view/718479000000031011/kanban?pipeline=718479000000517061
#O::Run, https://orbita.life/

^1::
Gui, Destroy
Gui, +AlwaysOnTop -SysMenu +ToolWindow
Gui, Margin, 10, 10
Gui, Color, 2A2F3B ; Темно-синій фон
Gui, Font, cD3D3D3 s12 Bold, Segoe UI
Gui, Add, Text, x10 y10 w780, Вставте сюди пріоритет для зручності, будь ласка. Ви можете це редагувати та підлаштовувати.

; Зчитуємо вміст файлу user_input.txt
FileRead, FileContent, %A_ScriptDir%\user_input.txt
if (ErrorLevel || FileContent = "") {  ; Якщо файл не існує або порожній
    FileContent := "Введіть текст тут..."
}

Gui, Add, Edit, x10 y50 w780 h400 vUserInput cBlack BackgroundWhite, %FileContent%
Gui, Add, Button, gSave x10 y460 w390 h40, Зберегти
Gui, Add, Button, gClose x410 y460 w390 h40, Закрити
Gui, Show, w800 h510, Пріоритет або замітка
return

Save:
Gui, Submit, NoHide
; Використовуємо FileAppend замість PowerShell для простоти та надійності
FileDelete, %A_ScriptDir%\user_input.txt
FileAppend, %UserInput%, %A_ScriptDir%\user_input.txt, UTF-8
Gui, Destroy
return

Close:
Gui, Destroy
return

; Контекстне меню (Ctrl + X)
^x::
MouseGetPos, mouseX, mouseY
Menu, MyMenu, Add, 🌐 Відкрити Google, RunGoogle
Menu, MyMenu, Add, 📱 Відкрити Telegram, RunTelegram
Menu, MyMenu, Add, 💬 Відкрити чат Viber, RunViber
Menu, MyMenu, Add, 💬 Відкрити чат WhatsApp, RunWhatsApp
Menu, MyMenu, Add, 🎥 Відкрити YouTube, RunYouTube
Menu, MyMenu, Add, 🌐 Відкрити Орбіту, RunOrbit
Menu, MyMenu, Add, ❌ Вихід, ExitScript
Menu, MyMenu, Show, %mouseX%, %mouseY%
return

RunGoogle:
Run, https://www.google.com
return

RunTelegram:
Run, "C:\Users\%A_UserName%\AppData\Roaming\Telegram Desktop\Telegram.exe"
return

RunViber:
    ; Запитуємо номер телефону через InputBox
    InputBox, phoneNumber, Введіть номер телефону, Введіть номер телефону для відкриття чату у Viber
    ; Якщо користувач ввів номер
    if (phoneNumber != "")
    {
        ; Видаляємо всі пробіли з початку і кінця номера телефону
        phoneNumber := Trim(phoneNumber)
        
        ; Перевіряємо, чи номер телефону має правильний формат
        if (phoneNumber ~= "^\+?\d+$")
        {
            Run, viber://chat?number=%phoneNumber%
        }
        else
        {
            MsgBox, Номер телефону має бути у форматі +380XXXXXXXXX.
        }
    }
    else
    {
        MsgBox, Ви не ввели номер телефону!
    }
return

RunWhatsApp:
    ; Запитуємо номер телефону через InputBox
    InputBox, phoneNumber, Введіть номер телефону, Введіть номер телефону для відкриття чату у WhatsApp
    ; Якщо користувач ввів номер
    if (phoneNumber != "")
    {
        ; Видаляємо всі пробіли з початку і кінця номера телефону
        phoneNumber := Trim(phoneNumber)
        
        ; Перевіряємо, чи номер телефону має правильний формат
        if (phoneNumber ~= "^\+?\d+$")
        {
            Run, whatsapp://send?phone=%phoneNumber%
        }
        else
        {
            MsgBox, Номер телефону має бути у форматі +380XXXXXXXXX або +77XXXXXXXXX.
        }
    }
    else
    {
        MsgBox, Ви не ввели номер телефону!
    }
return


RunYouTube:
Run, https://www.youtube.com
return

RunOrbit:
Run, https://orbita.life/
return

ExitScript:
return

; Вибір скриптів (Alt + 3)
!3::
Gui, Destroy
Gui, +AlwaysOnTop -SysMenu +ToolWindow
Gui, Margin, 10, 10
Gui, Color, 2A2F3B ; Темно-синій фон
Gui, Font, cD3D3D3 s12 Bold, Segoe UI
Gui, Add, Text, Center, Виберіть дію:`n`n
Gui, Font, cD3D3D3 s10 Bold, Segoe UI

; Група "Форми кандидатів"
Gui, Add, GroupBox, w700 h110 x10 y30 c808080, Форми кандидатів
Gui, Add, Button, gSendScript vFormaKZ w320 h30 x30 y50 -Border BackgroundB0B0B0, Форма кандидату КЗ
Gui, Add, Button, gSendScript vFormaUA w320 h30 x360 y50 -Border BackgroundB0B0B0, Форма кандидату Україна
Gui, Add, Button, gSendScript vZaprosSobes w320 h30 x30 y90 -Border BackgroundB0B0B0, Запросити на співбесіду

; Група "Відео презентації"
Gui, Add, GroupBox, w700 h110 x10 y150 c808080, Відео презентації
Gui, Add, Button, gSendScript vVideoIsida w320 h30 x30 y180 -Border BackgroundB0B0B0, Відео Ісіда КЗ
Gui, Add, Button, gSendScript vVideoWS w320 h30 x360 y180 -Border BackgroundB0B0B0, Відео ВС КЗ
Gui, Add, Button, gSendScript vVideoWSUA w320 h30 x30 y220 -Border BackgroundB0B0B0, Відео ВС Україна

; Група "Недозвони"
Gui, Add, GroupBox, w700 h110 x10 y265 c808080, Недозвони
Gui, Add, Button, gSendScript vNbtIsida w320 h30 x30 y290 -Border BackgroundB0B0B0, Недозвон Ісіда
Gui, Add, Button, gSendScript vNbtWS w320 h30 x360 y290 -Border BackgroundB0B0B0, Недозвон Вайт Скай
Gui, Add, Button, gSendScript vNbtWSUA w320 h30 x30 y330 -Border BackgroundB0B0B0, Недозвон ВС Укр

; Група "Пошук роботи та пропозиції"
Gui, Add, GroupBox, w700 h120 x10 y375 c808080, Пошук роботи та пропозиції
Gui, Add, Button, gSendScript vPoshukKZ w320 h30 x30 y410 -Border BackgroundB0B0B0, Пошук роботи КЗ
Gui, Add, Button, gSendScript vPoshukUA w320 h30 x360 y410 -Border BackgroundB0B0B0, Пошук роботи Україна
Gui, Add, Button, gSendScript vMojeforma w320 h30 x30 y450 -Border BackgroundB0B0B0, Запропонувати працевлаштування

; Група "Робочі моменти"
Gui, Add, GroupBox, w700 h155 x10 y495 c808080, Робочі моменти
Gui, Add, Button, gSendScript vObyazs w320 h30 x30 y525 -Border BackgroundB0B0B0, Обов'язки роботи
Gui, Add, Button, gSendScript vNavchannyaKZ w320 h30 x360 y525 -Border BackgroundB0B0B0, Привітати з працевлаштуванням КЗ
Gui, Add, Button, gSendScript vNavchannyaUA w320 h30 x30 y565 -Border BackgroundB0B0B0, Привітати з працевлаштуванням Україна
Gui, Add, Button, gSendScript vSarafanKZ w320 h30 x360 y565 -Border BackgroundB0B0B0, Сарафан КЗ
Gui, Add, Button, gSendScript vSarafanUA w320 h30 x30 y605 -Border BackgroundB0B0B0, Сарафан Україна

; Кнопка "Відмінити"
Gui, Add, Button, gClosecGui w200 h50 x250 y665 -Border BackgroundB0B0B0, Відмінити
Gui, Show, AutoSize Center, Вибір скрипту
return

; ===== Логіка для вставки тексту (Alt + 3) =====
FormaKZ:
    SendClipboardText("FormaKZ")
    Gui, Destroy ; Закриваємо GUI після відправки
return

FormaUA:
    SendClipboardText("FormaUA")
    Gui, Destroy ; Закриваємо GUI після відправки
return

ZaprosSobes:
    SendClipboardText("ZaprosSobes")
    Gui, Destroy ; Закриваємо GUI після відправки
return

VideoIsida:
    SendClipboardText("VideoIsida")
    Gui, Destroy ; Закриваємо GUI після відправки
return

VideoWS:
    SendClipboardText("VideoWS")
    Gui, Destroy ; Закриваємо GUI після відправки
return

VideoWSUA:
    SendClipboardText("VideoWSUA")
    Gui, Destroy ; Закриваємо GUI після відправки
return

NbtIsida:
    SendClipboardText("NbtIsida")
    Gui, Destroy ; Закриваємо GUI після відправки
return

NbtWS:
    SendClipboardText("NbtWS")
    Gui, Destroy ; Закриваємо GUI після відправки
return

NbtWSUA:
    SendClipboardText("NbtWSUA")
    Gui, Destroy ; Закриваємо GUI після відправки
return

PoshukKZ:
    SendClipboardText("PoshukKZ")
    Gui, Destroy ; Закриваємо GUI після відправки
return

PoshukUA:
    SendClipboardText("PoshukUA")
    Gui, Destroy ; Закриваємо GUI після відправки
return

Mojeforma:
    SendClipboardText("Mojeforma")
    Gui, Destroy ; Закриваємо GUI після відправки
return

Obyazs:
    SendClipboardText("Obyazs")
    Gui, Destroy ; Закриваємо GUI після відправки
return

NavchannyaKZ:
    SendClipboardText("NavchannyaKZ")
    Gui, Destroy ; Закриваємо GUI після відправки
return

NavchannyaUA:
    SendClipboardText("NavchannyaUA")
    Gui, Destroy ; Закриваємо GUI після відправки
return

SarafanKZ:
    SendClipboardText("SarafanKZ")
    Gui, Destroy ; Закриваємо GUI після відправки
return

SarafanUA:
    SendClipboardText("SarafanUA")
    Gui, Destroy ; Закриваємо GUI після відправки
return

SendClipboardText(scriptName) {
    ; Шлях до файлу, де зберігається текст для скрипту
    FilePath := A_ScriptDir "\scripts\" scriptName ".txt" 

    ; Перевірка, чи існує файл
    if !FileExist(FilePath) {
        MsgBox, 48, Помилка, Файл для скрипту %scriptName% не знайдено!
        return
    }

    ; Читаємо вміст файлу
    FileRead, ScriptText, %FilePath%

    ; Перевірка, чи файл не порожній
    if (ScriptText == "") {
        MsgBox, 48, Помилка, Файл %scriptName% порожній!
        return
    }

    ; Закриваємо GUI для того, щоб фокус був на чаті
    Gui, Destroy
    Sleep, 100 ; Затримка для стабільності після закриття GUI


    {
    FileRead, ScriptText, %FilePath%
    Clipboard := ScriptText ; Копіюємо текст у буфер обміну
    Send, ^v
    Sleep, 100 ; Затримка для стабільності
    Clipboard := "" ; Очищаємо буфер обміну
    }
}

SendScript:
SendClipboardText(A_GuiControl)
return


ClosecGui:
GuiClosec:
GuiEscapec:
Gui, Destroy
return


!8::
Gui, Destroy
Gui, +AlwaysOnTop -SysMenu +ToolWindow
Gui, Margin, 15, 15
Gui, Color, 2A2F3B ; Темно-синій фон
Gui, Font, cF5F5F5 s12 Bold, Segoe UI
Gui, Add, Text, x10 y10, Виберіть скрипт для редагування:`n
Gui, Font, c000000 s10 Normal, Segoe UI

; Асоціативний масив для мапінгу технічних назв на зрозумілі
ScriptNames := {}
ScriptNames["FormaKZ"] := "Форма кандидату КЗ"
ScriptNames["FormaUA"] := "Форма кандидату Україна"
ScriptNames["ZaprosSobes"] := "Запросити на співбесіду"
ScriptNames["VideoIsida"] := "Відео Ісіда КЗ"
ScriptNames["VideoWS"] := "Відео Вайт Скай КЗ"
ScriptNames["VideoWSUA"] := "Відео Вайт Скай Україна"
ScriptNames["NbtIsida"] := "Недозвон Ісіда"
ScriptNames["NbtWS"] := "Недозвон Вайт Скай"
ScriptNames["NbtWSUA"] := "Недозвон ВС Україна"
ScriptNames["PoshukKZ"] := "Пошук роботи КЗ"
ScriptNames["PoshukUA"] := "Пошук роботи Україна"
ScriptNames["Mojeforma"] := "Запропонувати працевлаштування"
ScriptNames["Obyazs"] := "Обов’язки роботи"
ScriptNames["NavchannyaKZ"] := "Привітати з працевлаштуванням КЗ"
ScriptNames["NavchannyaUA"] := "Привітати з працевлаштуванням Україна"
ScriptNames["SarafanKZ"] := "Сарафан КЗ"
ScriptNames["SarafanUA"] := "Сарафан Україна"

; Формуємо список для DropDownList із зрозумілими назвами
DropDownOptions := ""
for Key, Value in ScriptNames
    DropDownOptions .= Value "|"
StringTrimRight, DropDownOptions, DropDownOptions, 1 ; Видаляємо останній "|"

Gui, Add, DropDownList, vSelectedScript w340 x10 y40 +Tooltip, %DropDownOptions%
Gui, Add, Button, gEditScript w160 h40 x10 y90 +Border BackgroundD3D3D3, Редагувати
Gui, Add, Button, gClosseGui w160 h40 x180 y90 +Border BackgroundD3D3D3, Відмінити
Gui, Show, AutoSize Center, Редактор скриптів
return

EditScript:
Gui, Submit, NoHide
; Знаходимо технічну назву за зрозумілою назвою
SelectedTechName := ""
for Key, Value in ScriptNames {
    if (Value = SelectedScript) {
        SelectedTechName := Key
        break
    }
}
if (!SelectedTechName) {
    MsgBox, 48, Помилка, Не знайдено відповідного скрипту!
    return
}

FilePath := A_ScriptDir "\scripts\" SelectedTechName ".txt"
if !FileExist(FilePath)
    FileAppend,, %FilePath%, UTF-8
FileRead, ScriptText, %FilePath%
Gui, Destroy
Gui, +AlwaysOnTop -SysMenu +ToolWindow
Gui, Margin, 15, 15
Gui, Color, 1E2A44
Gui, Font, cF5F5F5 s12 Bold, Segoe UI
Gui, Add, Text, x10 y10, Відредагуйте текст для скрипту: %SelectedScript%
Gui, Add, Edit, vEditedScriptText w720 h400 x10 y40 c000000 BackgroundWhite, %ScriptText%
Gui, Add, Button, gSaveScript w340 h40 x10 y450 +Border BackgroundD3D3D3, Зберегти
Gui, Add, Button, gClosseGui w340 h40 x360 y450 +Border BackgroundD3D3D3, Відмінити
Gui, Show, AutoSize Center, Редагування: %SelectedScript%
return

SaveScript:
Gui, Submit, NoHide
; Знаходимо технічну назву за зрозумілою назвою для збереження
SelectedTechName := ""
for Key, Value in ScriptNames {
    if (Value = SelectedScript) {
        SelectedTechName := Key
        break
    }
}
if (!SelectedTechName) {
    MsgBox, 48, Помилка, Не знайдено відповідного скрипту!
    return
}

FilePath := A_ScriptDir "\scripts\" SelectedTechName ".txt"
FileDelete, %FilePath%
FileAppend, %EditedScriptText%, %FilePath%, UTF-8
MsgBox, 64, Успішно!, Текст для скрипту %SelectedScript% збережено!
Gui, Destroy
return

; Закриття GUI
ClosseGui:
GuiClosse:
GuiEsscape:
Gui, Destroy
return

^2::
Gui, Destroy
Gui, +AlwaysOnTop -SysMenu +ToolWindow
Gui, Margin, 10, 10 ; Залишаємо відступи
Gui, Color, 2A2F3B ; Темно-синій фон
Gui, Font, cF5F5F5 s12 Bold, Segoe UI ; Кремовий текст для заголовка
Gui, Add, Text, Center, Оберіть пропис:`n`n
Gui, Font, cF5F5F5 s10 Bold, Segoe UI ; М’якший шрифт для кнопок

; Масив причин (залишаємо без змін)
Reasons := {}
Reasons["PropisAdm"] := "Привіт, скажи будь ласка, люди почали навчання?"
Reasons["PropisCh"] := "Здравствуйте, удалось ли Вам начать обучение? Администратор с Вами связался?"
Reasons["StajLud"] := "Здравствуйте, удалось ли Вам начать работу на сайте? Может у Вас есть какие-то трудности? Как Вам работа администратора?"
Reasons["SputSait"] := "Привіт, людина дійшла до сайту?"
Reasons["SputKolu"] := "Когда Вы будете готовы начать обучение?"
Reasons["Oznayom"] := "Удалось ли Вам ознакомится с видео? Всё ли Вам подходит?"
Reasons["EVoprosi"] := "Возможно у Вас есть какие-либо вопросы или может желаете что-нибудь уточнить?"
Reasons["TochnoNema"] := "Возможно у Вас есть ещё вопросы касаемо вакансии?"
Reasons["KoluPochatok"] := "Когда бы Вы желали выйти на обучение да и в целом начать?"
Reasons["YakPonyav"] := "Как Вы поняли Ваши обязанности, чем Вы будете заниматься в рабочем пространстве?"
Reasons["ChiGotov"] := "Готовы ли Вы начинать в ближайшее время?"
Reasons["YakaRobota"] := "Какую работу Вы для себя ищете? Основную или подработку?"
Reasons["ChiAktual"] := "Здравствуйте, для Вас работа актуальная?"

; Кнопки з групуванням, без рамок, м’якший фон
Gui, Add, GroupBox, w700 h180 x10 y30 c808080, Прописи ; Світліший колір для GroupBox
Gui, Add, Button, gInseertReason vPropisAdm w320 h30 x30 y60 -Border BackgroundB0B0B0, Пропис адміна
Gui, Add, Button, gInseertReason vPropisCh w320 h30 x360 y60 -Border BackgroundB0B0B0, Пропис людини
Gui, Add, Button, gInseertReason vStajLud w320 h30 x30 y110 -Border BackgroundB0B0B0, Стажування людини
Gui, Add, Button, gInseertReason vSputSait w320 h30 x360 y110 -Border BackgroundB0B0B0, Спитати за сайт
Gui, Add, Button, gInseertReason vSputKolu w320 h30 x30 y160 -Border BackgroundB0B0B0, Спитати коли починає

Gui, Add, GroupBox, w700 h220 x10 y210 c808080, Робочі моменти
Gui, Add, Button, gInseertReason vOznayom w320 h30 x30 y240 -Border BackgroundB0B0B0, Чи вдалось ознайомитись
Gui, Add, Button, gInseertReason vEVoprosi w320 h30 x360 y240 -Border BackgroundB0B0B0, Чи є питання
Gui, Add, Button, gInseertReason vTochnoNema w320 h30 x30 y290 -Border BackgroundB0B0B0, Чи є ще питання
Gui, Add, Button, gInseertReason vKoluPochatok w320 h30 x360 y290 -Border BackgroundB0B0B0, Коли бажає починати
Gui, Add, Button, gInseertReason vYakPonyav w320 h30 x30 y340 -Border BackgroundB0B0B0, Як зрозумів обов'язки
Gui, Add, Button, gInseertReason vChiGotov w320 h30 x360 y340 -Border BackgroundB0B0B0, Чи готовий працювати

Gui, Add, GroupBox, w700 h80 x10 y430 c808080, Уточнення
Gui, Add, Button, gInseertReason vYakaRobota w320 h40 x30 y460 -Border BackgroundB0B0B0, Яку роботу шукає
Gui, Add, Button, gInseertReason vChiAktual w320 h40 x360 y460 -Border BackgroundB0B0B0, Чи актуальний пошук

Gui, Add, Button, gCloseGuii w200 h50 x270 y530 -Border BackgroundB0B0B0, Відмінити
Gui, Show, AutoSize Center, Вибір причини
return

InseertReason:
InseertText(Reasons[A_GuiControl])
return

; Функція для вставки тексту (додаємо її, якщо її немає в коді)
InseertText(Text) {
    Gui, Destroy
    Clipboard := Text
    Send, ^v
    Sleep, 50
    Clipboard := ""
}

CloseGuii:
GuiiClose:
GuiiEscape:
Gui, Destroy
return