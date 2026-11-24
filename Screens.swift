import UniformTypeIdentifiers
import SwiftUI
import UIKit

// MARK: - Today

struct TodayView: View {
    @EnvironmentObject var store: Store
    @State private var active: Session?

    private var isFriday: Bool { Calendar.current.component(.weekday, from: Date()) == 6 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    HStack(spacing: 12) {
                        sessionButton(.am)
                        sessionButton(.pm)
                    }
                    phasePicker
                    weekStrip
                    InfoBox(title: "الإحماء (3 دقائق قبل كل جلسة)", items: [
                        "المشي في المكان دقيقة",
                        "دوائر الكتفين للأمام والخلف، 10 لكل اتجاه",
                        "دوائر الحوض والوسط، 8 لكل اتجاه",
                        "جلوس نصفي ثم وقوف ببطء، 8 مرات"
                    ])
                    InfoBox(title: "الإطالة بعد كل جلسة", items: [
                        "المشي الهادئ دقيقة مع تنفس عميق",
                        "إطالة الصدر على إطار الباب، 20 ثانية",
                        "إطالة الفخذ الخلفي جالسًا على كرسي، 20 ثانية لكل ساق",
                        "إطالة عضلة الساق الخلفية على الحائط، 20 ثانية لكل ساق"
                    ])
                    InfoBox(title: "قواعد السلامة", items: [
                        "الألم الحاد في مفصل يعني توقّف. أما تعب العضلات والحرقة الخفيفة فطبيعيان.",
                        "في الفجر جسمك أكثر تيبّسًا، فلا تختصر الإحماء.",
                        "اجعل جلسة المساء قبل النوم بساعة تقريبًا، ثم الإطالة والشاور الدافئ.",
                        "تنفّس طوال الوقت ولا تحبس نفسك.",
                        "استخدم كرسيًا ثابتًا بلا عجلات، ويُفضَّل أن يكون مسنودًا إلى الحائط.",
                        "خسارة الوزن تأتي أساسًا من الأكل، والتمارين والمشي يكمّلانه.",
                        "إن كان لديك مرض في القلب أو ضغط غير منتظم أو إصابة سابقة، استشر طبيبك قبل البدء."
                    ])
                }
                .padding()
            }
            .navigationTitle("تمريني")
        }
        .fullScreenCover(item: $active) { s in
            WorkoutView(session: s).environmentObject(store)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isFriday {
                Text("اليوم الجمعة: راحة").font(.title2.bold())
                Text("مشي خفيف \(phases[store.phase].walk) دقيقة إن رغبت.").foregroundStyle(.secondary)
            } else {
                Text(Calendar.current.component(.hour, from: Date()) < 12 ? "وقت جلسة الفجر ☀" : "جلسة المساء قبل الشاور ☾")
                    .font(.title2.bold())
                if let t = store.morningTime(on: Date()) {
                    Text("تنبيه الفجر اليوم \(t.formatted(date: .omitted, time: .shortened))، والمساء \(store.eveningDate.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Text("أنجزت \(store.doneCount) من 144 جلسة")
                .font(.subheadline.weight(.semibold))
        }
    }

    private func sessionButton(_ s: Session) -> some View {
        Button { active = s } label: {
            VStack(spacing: 6) {
                Image(systemName: s.icon).font(.title)
                Text(s.title).font(.headline)
                Text(s.subtitle).font(.caption).opacity(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(s == .am ? Color.brand : Color.figure, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(s == .am ? Color.black : Color.white)
        }
        .buttonStyle(.plain)
    }

    private var phasePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("المرحلة").font(.headline)
            Picker("المرحلة", selection: $store.phase) {
                ForEach(0..<phases.count, id: \.self) { i in Text(phases[i].name).tag(i) }
            }
            .pickerStyle(.segmented)
            Text("\(phases[store.phase].weeks): \(phases[store.phase].note)")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var weekStrip: some View {
        HStack(spacing: 5) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 2) {
                    Text(i < 6 ? dayNames[i] : "الجمعة").font(.caption2.weight(.semibold))
                    Text(i < 6 ? "☀ ☾" : "راحة").font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(i < 6 ? Color.brand.opacity(0.85) : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(i < 6 ? Color.black : Color.secondary)
            }
        }
    }
}

struct InfoBox: View {
    let title: String
    let items: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text(item).fixedSize(horizontal: false, vertical: true)
                }
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Exercises

struct ExercisesView: View {
    @EnvironmentObject var store: Store
    var body: some View {
        NavigationStack {
            List {
                ForEach(Session.allCases) { s in
                    Section(s.title) {
                        ForEach(sessionExercises(s)) { e in
                            NavigationLink { ExerciseDetail(exercise: e) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(e.name).font(.headline)
                                    Text("\(e.rx[store.phase]) · \(e.variants[store.phase])")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("التمارين")
        }
    }
}

struct ExerciseDetail: View {
    @EnvironmentObject var store: Store
    let exercise: Exercise

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ExerciseMedia(exercise: exercise)
                HStack {
                    Text(exercise.rx[store.phase]).font(.headline)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(Color.brand.opacity(0.3), in: Capsule())
                    Text(exercise.variants[store.phase]).font(.subheadline).foregroundStyle(.secondary)
                }
                Text("طريقة الأداء").font(.title3.bold())
                ForEach(Array(exercise.steps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(i + 1)").font(.headline).frame(width: 26, height: 26)
                            .background(Color.figure.opacity(0.15), in: Circle())
                        Text(step).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Text("أخطاء شائعة").font(.title3.bold())
                ForEach(exercise.mistakes, id: \.self) { m in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                        Text(m).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Text("العضلات المستهدفة: \(exercise.muscles)").foregroundStyle(.secondary)
                Text(exercise.tip)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.brand.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Workout

struct WorkoutStep: Identifiable {
    let id: Int
    let exercise: Exercise
    let round: Int
}

struct WorkoutView: View {
    let session: Session
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    enum Stage { case exercise, rest, finished }

    @State private var steps: [WorkoutStep] = []
    @State private var pos = 0
    @State private var stage: Stage = .exercise
    @State private var remaining = 0
    @State private var counting = false
    @State private var timedStarted = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var phase: Phase { phases[store.phase] }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(stage == .finished ? "انتهت الجلسة" : "التمرين \(min(pos + 1, max(steps.count, 1))) من \(steps.count)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("إنهاء") { dismiss() }
                    .buttonStyle(.bordered)
            }
            ProgressView(value: Double(stage == .finished ? steps.count : pos), total: Double(max(steps.count, 1)))
                .tint(Color.brand)
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
        }
        .padding()
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            var list: [WorkoutStep] = []
            for r in 1...phase.rounds {
                for e in sessionExercises(session) { list.append(WorkoutStep(id: list.count, exercise: e, round: r)) }
            }
            steps = list
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onReceive(tick) { _ in
            guard counting, remaining > 0 else { return }
            remaining -= 1
            if remaining == 0 {
                counting = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if stage == .rest { stage = .exercise; timedStarted = false }
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch stage {
        case .exercise:
            if pos < steps.count {
                let step = steps[pos]
                let e = step.exercise
                VStack(spacing: 10) {
                    ExerciseMedia(exercise: e)
                    Text(e.name).font(.title2.bold()).multilineTextAlignment(.center)
                    Text(e.rx[store.phase]).font(.title3.weight(.semibold))
                    Text("الجولة \(step.round) من \(phase.rounds) · \(e.variants[store.phase])")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Text(e.steps[2]).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    if let timed = e.timed {
                        if timedStarted {
                            Text(remaining == 0 ? "تم ✓" : "\(remaining)")
                                .font(.system(size: 64, weight: .light, design: .rounded)).monospacedDigit()
                        } else {
                            Button("ابدأ العدّ \(timed[store.phase]) ثانية") {
                                remaining = timed[store.phase]; counting = true; timedStarted = true
                            }
                            .buttonStyle(.bordered).controlSize(.large)
                        }
                    }
                    bigButton("أنهيت هذا التمرين") { next() }
                }
            }
        case .rest:
            VStack(spacing: 14) {
                Text("استراحة، تنفّس بعمق واشرب ماء").foregroundStyle(.secondary)
                Text(format(remaining))
                    .font(.system(size: 80, weight: .light, design: .rounded)).monospacedDigit()
                if pos < steps.count {
                    Text("التالي: \(steps[pos].exercise.name)").font(.headline)
                }
                bigButton("تخطَّ الراحة") { counting = false; stage = .exercise; timedStarted = false }
                Button("أضف 15 ثانية") { remaining += 15; counting = true }
                    .buttonStyle(.bordered).controlSize(.large)
            }
        case .finished:
            VStack(spacing: 14) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundStyle(Color.brand)
                Text("أحسنت، سُجّلت الجلسة").font(.title2.bold())
                Text(session == .am ? "إطالة سريعة دقيقتين، ثم انطلق لدوامك بنشاط."
                                    : "الآن الإطالة خمس دقائق، ثم الشاور الدافئ والنوم.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
                bigButton("العودة") { dismiss() }
            }
        }
    }

    private func next() {
        counting = false
        timedStarted = false
        pos += 1
        if pos >= steps.count {
            stage = .finished
            store.markDone(session)
        } else {
            remaining = phase.rest
            counting = true
            stage = .rest
        }
    }

    private func format(_ s: Int) -> String {
        s >= 60 ? String(format: "%d:%02d", s / 60, s % 60) : "\(s)"
    }

    private func bigButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.figure, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress

struct ProgressGridView: View {
    @EnvironmentObject var store: Store
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("أنجزت \(store.doneCount) من 144 جلسة").font(.headline)
                    Text("لكل أسبوع صفّان: ☀ للفجر و☾ للمساء، من السبت إلى الخميس. اضغط أي مربع لتعديله.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<12, id: \.self) { w in weekCard(w) }
                    }
                }
                .padding()
            }
            .navigationTitle("التقدّم")
        }
    }

    private func weekCard(_ w: Int) -> some View {
        VStack(spacing: 6) {
            Text("الأسبوع \(w + 1)").font(.caption.weight(.semibold))
            ForEach(Session.allCases) { s in
                HStack(spacing: 4) {
                    Text(s == .am ? "☀" : "☾").font(.caption2).frame(width: 14)
                    ForEach(0..<6, id: \.self) { d in
                        let i = Store.index(week: w, session: s, day: d)
                        Button { store.done[i].toggle() } label: {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(store.done[i] ? Color.figure : Color(.systemBackground))
                                .overlay(RoundedRectangle(cornerRadius: 5)
                                    .stroke(store.done[i] ? Color.figure : Color.gray.opacity(0.4), lineWidth: 1.5))
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var testSent = false
    @State private var importing = false
    @State private var importResult: String?

    private var offsetText: String {
        let m = store.morningOffset
        if m == 0 { return "مع الشروق تمامًا" }
        return m < 0 ? "قبل الشروق بـ \(-m) دقيقة" : "بعد الشروق بـ \(m) دقيقة"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("تفعيل التنبيهات", isOn: $store.remindersOn)
                }
                Section {
                    NavigationLink { LocationPicker() } label: {
                        LabeledContent("المدينة", value: store.place.title)
                    }
                    Stepper(offsetText, value: $store.morningOffset, in: -90...90, step: 5)
                    if let sr = Sun.sunrise(on: Date(), lat: store.place.lat, lon: store.place.lon),
                       let t = store.morningTime(on: Date()) {
                        LabeledContent("الشروق اليوم", value: sr.formatted(date: .omitted, time: .shortened))
                        LabeledContent("تنبيه الفجر اليوم", value: t.formatted(date: .omitted, time: .shortened))
                    }
                } header: {
                    Text("🌅 جلسة الفجر")
                } footer: {
                    Text("وقت الشروق محسوب بطريقة تقويم أم القرى، ويتغير التنبيه تلقائيًا مع تغيّر الشروق خلال السنة.")
                }
                Section("🌙 جلسة المساء") {
                    DatePicker("الوقت", selection: $store.eveningDate, displayedComponents: .hourAndMinute)
                }
                Section {
                    Button(testSent ? "سيصلك تنبيه بعد 5 ثوانٍ" : "أرسل تنبيهًا تجريبيًا") {
                        Reminders.test(); testSent = true
                    }
                } footer: {
                    Text("التنبيهات من السبت إلى الخميس، والجمعة راحة. إن لم يصلك التنبيه، افتح إعدادات الآيفون ← الإشعارات ← تمريني، وتأكد أنها مفعّلة.")
                }
                Section {
                    LabeledContent("الجلسات المحفوظة", value: "\(store.doneCount) من 144")
                    if let url = store.exportBackup() {
                        ShareLink(item: url) { Label("حفظ نسخة احتياطية في الملفات", systemImage: "square.and.arrow.up") }
                    }
                    Button { importing = true } label: {
                        Label("استرجاع من نسخة احتياطية", systemImage: "square.and.arrow.down")
                    }
                    if let r = importResult { Text(r).font(.footnote) }
                } header: {
                    Text("💾 الحفظ")
                } footer: {
                    Text("كل شيء يُحفظ تلقائيًا في جوالك لحظة بلحظة: تقدّمك والمرحلة والمدينة والأوقات. ويبقى محفوظًا في خزنة الجوال حتى لو حذفت التطبيق وأعدت تثبيته. وللاحتياط عند تغيير الجوال، احفظ نسخة في تطبيق الملفات أو iCloud Drive.")
                }
                if let installed = Reminders.installDate() {
                    Section("صلاحية التثبيت") {
                        let exp = installed.addingTimeInterval(7 * 24 * 3600)
                        LabeledContent("ينتهي تقريبًا", value: exp.formatted(date: .abbreviated, time: .omitted))
                        Text("بحساب Apple المجاني يعمل التطبيق 7 أيام. أعد تثبيته من Sideloadly قبلها، وبياناتك تبقى محفوظة.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("الإعدادات")
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                if case .success(let url) = result, store.importBackup(from: url) {
                    importResult = "✅ تم استرجاع بياناتك."
                } else {
                    importResult = "تعذّر قراءة الملف. اختر ملف tamreeni-backup.json."
                }
            }
        }
    }
}

// MARK: - Location picker

struct LocationPicker: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @StateObject private var search = PlaceSearch()
    @StateObject private var locator = LocationFetcher()
    @State private var query = ""

    var body: some View {
        List {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                Section {
                    Button {
                        locator.fetch { p in store.place = p; dismiss() }
                    } label: {
                        HStack {
                            Label("استخدم موقعي الحالي", systemImage: "location.fill")
                            Spacer()
                            if locator.busy { ProgressView() }
                        }
                    }
                    if let e = locator.error { Text(e).font(.footnote).foregroundStyle(.red) }
                } footer: {
                    Text("أو ابحث عن أي مدينة في العالم من خانة البحث، أو اختر من القائمة.")
                }
                Section("الدول") {
                    ForEach(countries) { c in
                        NavigationLink(c.name) { CityList(country: c, onPick: { dismiss() }) }
                    }
                }
            } else {
                Section {
                    if search.searching { ProgressView() }
                    ForEach(Array(search.results.enumerated()), id: \.offset) { _, p in
                        Button { store.place = p; dismiss() } label: {
                            VStack(alignment: .leading) {
                                Text(p.name).foregroundStyle(.primary)
                                Text(p.country).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if !search.searching && search.results.isEmpty {
                        Text("لا نتائج بعد. اكتب اسم المدينة كاملًا، والبحث يحتاج إنترنت.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "ابحث عن مدينة")
        .onSubmit(of: .search) { search.search(query) }
        .onChange(of: query) { q in search.search(q) }
        .navigationTitle("اختر المدينة")
    }
}

struct CityList: View {
    @EnvironmentObject var store: Store
    let country: Country
    let onPick: () -> Void

    var body: some View {
        List {
            ForEach(country.cities, id: \.0) { city in
                Button {
                    store.place = Place(name: city.0, country: country.name, lat: city.1, lon: city.2)
                    onPick()
                } label: {
                    HStack {
                        Text(city.0).foregroundStyle(.primary)
                        Spacer()
                        if store.place.name == city.0 && store.place.country == country.name {
                            Image(systemName: "checkmark").foregroundStyle(Color.figure)
                        }
                    }
                }
            }
        }
        .navigationTitle(country.name)
    }
}
