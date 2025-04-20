// lib/main.dart import 'package:flutter/material.dart'; import 'package:provider/provider.dart'; import 'dart:convert'; import 'package:shared_preferences/shared_preferences.dart';

void main() async { WidgetsFlutterBinding.ensureInitialized(); final provider = BudgetProvider(); await provider.loadData(); runApp( ChangeNotifierProvider( create: (_) => provider, child: BudgetApp(), ), ); }

class BudgetApp extends StatelessWidget { @override Widget build(BuildContext context) { return MaterialApp( title: 'Budget Tracker', theme: ThemeData.light(), darkTheme: ThemeData.dark(), home: ProjectListScreen(), ); } }

// Models class Task { String id, desc, category, date; double amount; Task({ required this.id, required this.desc, required this.amount, required this.category, required this.date, }); factory Task.fromJson(Map<String, dynamic> j) => Task( id: j['id'], desc: j['desc'], amount: j['amount'], category: j['category'], date: j['date'], ); Map<String, dynamic> toJson() => { 'id': id, 'desc': desc, 'amount': amount, 'category': category, 'date': date, }; }

class Project { String id, name; double budget; List<Task> tasks; Project({ required this.id, required this.name, required this.budget, required this.tasks, }); factory Project.fromJson(Map<String, dynamic> j) => Project( id: j['id'], name: j['name'], budget: j['budget'], tasks: (j['tasks'] as List).map((t) => Task.fromJson(t)).toList(), ); Map<String, dynamic> toJson() => { 'id': id, 'name': name, 'budget': budget, 'tasks': tasks.map((t) => t.toJson()).toList(), }; }

// State Provider class BudgetProvider extends ChangeNotifier { List<Project> projects = [];

Future<void> loadData() async { final prefs = await SharedPreferences.getInstance(); final str = prefs.getString('budget_data'); if (str != null) { final list = json.decode(str) as List; projects = list.map((e) => Project.fromJson(e)).toList(); } notifyListeners(); }

Future<void> saveData() async { final prefs = await SharedPreferences.getInstance(); final str = json.encode(projects.map((p) => p.toJson()).toList()); await prefs.setString('budget_data', str); }

void addProject(Project p) { projects.add(p); saveData(); notifyListeners(); }

void updateProject(Project p) { final idx = projects.indexWhere((x) => x.id == p.id); if (idx >= 0) projects[idx] = p; saveData(); notifyListeners(); }

void deleteProject(String id) { projects.removeWhere((p) => p.id == id); saveData(); notifyListeners(); }

void duplicateProject(String id) { final orig = projects.firstWhere((p) => p.id == id); final copy = Project( id: DateTime.now().millisecondsSinceEpoch.toString(), name: orig.name + ' Copy', budget: orig.budget, tasks: orig.tasks .map((t) => Task( id: DateTime.now().millisecondsSinceEpoch.toString(), desc: t.desc, amount: t.amount, category: t.category, date: t.date, )) .toList(), ); projects.add(copy); saveData(); notifyListeners(); }

void resetAll() { projects.clear(); saveData(); notifyListeners(); } }

// Screens class ProjectListScreen extends StatelessWidget { @override Widget build(BuildContext context) { final prov = context.watch<BudgetProvider>(); return Scaffold( appBar: AppBar( title: Text('Projects'), actions: [ IconButton(icon: Icon(Icons.refresh), onPressed: prov.resetAll), ], ), body: ListView( children: prov.projects .map((p) => ListTile( title: Text(p.name), subtitle: Text( 'Budget: $${p.budget.toStringAsFixed(2)} | Spent: $${p.tasks.fold(0.0, (s, t) => (s as double) + t.amount).toStringAsFixed(2)}'), onTap: () => Navigator.push( context, MaterialPageRoute( builder: (_) => ProjectDetailScreen(project: p))), trailing: PopupMenuButton<String>( onSelected: (v) { if (v == 'edit') editProject(context, p); if (v == 'delete') prov.deleteProject(p.id); if (v == 'dup') prov.duplicateProject(p.id); }, itemBuilder: () => [ PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'dup', child: Text('Duplicate')), PopupMenuItem(value: 'delete', child: Text('Delete')), ], ), )) .toList(), ), floatingActionButton: FloatingActionButton( child: Icon(Icons.add), onPressed: () => _newProject(context), ), ); }

void newProject(BuildContext ctx) { final nameCtrl = TextEditingController(); final budgetCtrl = TextEditingController(); showDialog( context: ctx, builder: () => AlertDialog( title: Text('New Project'), content: Column(mainAxisSize: MainAxisSize.min, children: [ TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name')), TextField( controller: budgetCtrl, decoration: InputDecoration(labelText: 'Budget'), keyboardType: TextInputType.number), ]), actions: [ TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(ctx)), ElevatedButton( child: Text('Add'), onPressed: () { final p = Project( id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text, budget: double.tryParse(budgetCtrl.text) ?? 0, tasks: [], ); ctx.read<BudgetProvider>().addProject(p); Navigator.pop(ctx); }), ], ), ); }

void editProject(BuildContext ctx, Project p) { final nameCtrl = TextEditingController(text: p.name); final budgetCtrl = TextEditingController(text: p.budget.toString()); showDialog( context: ctx, builder: () => AlertDialog( title: Text('Edit Project'), content: Column(mainAxisSize: MainAxisSize.min, children: [ TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name')), TextField( controller: budgetCtrl, decoration: InputDecoration(labelText: 'Budget'), keyboardType: TextInputType.number), ]), actions: [ TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(ctx)), ElevatedButton( child: Text('Save'), onPressed: () { final updated = Project( id: p.id, name: nameCtrl.text, budget: double.tryParse(budgetCtrl.text) ?? p.budget, tasks: p.tasks, ); ctx.read<BudgetProvider>().updateProject(updated); Navigator.pop(ctx); }), ], ), ); } }

class ProjectDetailScreen extends StatelessWidget { final Project project; ProjectDetailScreen({required this.project}); @override Widget build(BuildContext context) { final prov = context.watch<BudgetProvider>(); final proj = prov.projects.firstWhere((p) => p.id == project.id); final spent = proj.tasks.fold(0.0, (s, t) => (s as double) + t.amount);

return Scaffold(
  appBar: AppBar(title: Text(proj.name)),
  body: Padding(
    padding: EdgeInsets.all(12),
    child: Column(children: [
      Text('Budget: \$${proj.budget.toStringAsFixed(2)}'),
      Text('Spent: \$${spent.toStringAsFixed(2)}'),
      Expanded(
        child: ListView(
          children: proj.tasks
              .map((t) => ListTile(
                    title: Text(t.desc),
                    subtitle:
                        Text('\$${t.amount} | ${t.category} | ${t.date}'),
                    onLongPress: () => _editTask(context, proj, t),
                    trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          proj.tasks.removeWhere((x) => x.id == t.id);
                          prov.updateProject(proj);
                        }),
                  ))
              .toList(),
        ),
      ),
    ]),
  ),
  floatingActionButton: FloatingActionButton(
    child: Icon(Icons.add),
    onPressed: () => _newTask(context, proj),
  ),
);

}

void newTask(BuildContext ctx, Project p) { final descCtrl = TextEditingController(); final amtCtrl = TextEditingController(); final catCtrl = TextEditingController(); final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T').first); showDialog( context: ctx, builder: () => AlertDialog( title: Text('New Task'), content: Column(mainAxisSize: MainAxisSize.min, children: [ TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Desc')), TextField( controller: amtCtrl, decoration: InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number), TextField(controller: catCtrl, decoration: InputDecoration(labelText: 'Category')), TextField(controller: dateCtrl, decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)')), ]), actions: [ TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(ctx)), ElevatedButton( child: Text('Add'), onPressed: () { final task = Task( id: DateTime.now().millisecondsSinceEpoch.toString(), desc: descCtrl.text, amount: double.tryParse(amtCtrl.text) ?? 0, category: catCtrl.text, date: dateCtrl.text, ); p.tasks.add(task); ctx.read<BudgetProvider>().updateProject(p); Navigator.pop(ctx); }), ], ), ); }

void editTask(BuildContext ctx, Project p, Task t) { final descCtrl = TextEditingController(text: t.desc); final amtCtrl = TextEditingController(text: t.amount.toString()); final catCtrl = TextEditingController(text: t.category); final dateCtrl = TextEditingController(text: t.date); showDialog( context: ctx, builder: () => AlertDialog( title: Text('Edit Task'), content: Column(mainAxisSize: MainAxisSize.min, children: [ TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Desc')), TextField( controller: amtCtrl, decoration: InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number), TextField(controller: catCtrl, decoration: InputDecoration(labelText: 'Category')), TextField(controller: dateCtrl, decoration: InputDecoration(labelText: 'Date')), ]), actions: [ TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(ctx)), ElevatedButton( child: Text('Save'), onPressed: () { t.desc = descCtrl.text; t.amount = double.tryParse(amtCtrl.text) ?? t.amount; t.category = catCtrl.text; t.date = dateCtrl.text; ctx.read<BudgetProvider>().updateProject(p); Navigator.pop(ctx); }), ], ), ); } }

