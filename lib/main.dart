import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

@immutable
class Person {
  final String name;
  final int age;
  final String uuid;

  Person({required this.name, required this.age, String? uuid})
      : this.uuid = uuid ?? const Uuid().v4();

  Person updated([String? name, int? age]) {
    return Person(name: name ?? this.name, age: age ?? this.age, uuid: uuid);
  }

  String get getDisplayName => '$name ($age years old)';

  @override
  bool operator ==(covariant Person other) => uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() => 'Person(name: $name, age:$age, uuid: $uuid)';
}

class DataModel extends ChangeNotifier {
  final List<Person> _people = [];
  int get count => _people.length;
  UnmodifiableListView<Person> get people => UnmodifiableListView(
      _people); // so that outside world cannot modify the list

  void add(Person person) {
    _people.add(person);
    notifyListeners();
  }

  void remove(Person person) {
    _people.remove(person);
    notifyListeners();
  }

  void update(Person updatedPerson) {
    final index = _people.indexOf(updatedPerson);
    final oldPerson = _people[index];
    if (oldPerson.name != updatedPerson.name ||
        oldPerson.age != updatedPerson.age) {
      _people[index] = oldPerson.updated(
        updatedPerson.name,
        updatedPerson.age,
      );
      notifyListeners();
    }
  }
}

final peopleProvider = ChangeNotifierProvider((_) => DataModel());

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final dataModel = ref.watch(peopleProvider);
          return ListView.builder(
              itemCount: dataModel.count,
              itemBuilder: ((context, index) {
                final person = dataModel.people[index];
                return ListTile(
                  onTap: () async {
                    final updatedPerson =
                        await createOrUpdatePersonDialog(context, person);
                    if (updatedPerson != null) {
                      dataModel.update(updatedPerson);
                    }
                  },
                  title: Text(person.getDisplayName),
                );
              }));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final person = await createOrUpdatePersonDialog(context);

          if (person != null) {
            final dataModel = ref.read(peopleProvider);
            dataModel.add(person);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

final nameController = TextEditingController();
final ageController = TextEditingController();

Future<Person?> createOrUpdatePersonDialog(BuildContext context,
    [Person? existingPerson]) {
  String? name = existingPerson?.name;
  int? age = existingPerson?.age;

  nameController.text = name ?? '';
  ageController.text = age?.toString() ?? '';

  return showDialog<Person?>(
      context: context,
      builder: ((context) {
        return AlertDialog(
          title: const Text('Create a Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Enter Name Here'),
                onChanged: (value) => name = value,
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(hintText: 'Enter Age Here'),
                onChanged: (value) => age = int.tryParse(value),
              )
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  if (name != null && age != null) {
                    if (existingPerson != null) {
                      /// exist and update
                      final newPerson = existingPerson.updated(
                        name,
                        age,
                      );
                      Navigator.pop(context, newPerson);
                    } else {
                      // does not exist and create a new one
                      Navigator.pop(context, Person(name: name!, age: age!));
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save')),
          ],
        );
      }));
}
