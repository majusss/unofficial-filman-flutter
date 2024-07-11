import 'package:unofficial_filman_client/notifiers/filman.dart';
import 'package:unofficial_filman_client/notifiers/settings.dart';
import 'package:unofficial_filman_client/notifiers/watched.dart';
import 'package:unofficial_filman_client/screens/film.dart';
import 'package:unofficial_filman_client/screens/player.dart';
import 'package:unofficial_filman_client/types/watched.dart';
import 'package:unofficial_filman_client/utils/titlte.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WatchedPage extends StatefulWidget {
  const WatchedPage({super.key});

  @override
  State<WatchedPage> createState() => _WatchedPageState();
}

class _WatchedPageState extends State<WatchedPage> {
  Widget _buildWatchedFilmCard(
      BuildContext context, WatchedSingle film, WatchedNotifier all) {
    return Card(
        child: Stack(
      children: [
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => FilmanPlayer.fromDetails(
                        filmDetails: film.filmDetails,
                        startFrom: film.watchedInSec,
                        savedDuration: film.totalInSec,
                      )),
            );
          },
          onLongPress: () => showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Usuwanie z historii'),
                content: Consumer<SettingsNotifier>(
                  builder: (context, settings, child) => Text(
                      'Czy na pewno chcesz usunąć postęp oglądania \'${getDisplayTitle(film.filmDetails.title, settings)}\' z historii?'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Anuluj'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        Provider.of<WatchedNotifier>(context, listen: false)
                            .remove(film);
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Usuń'),
                  ),
                ],
              );
            },
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4.0)),
                  child: Image.network(
                    film.filmDetails.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              LinearProgressIndicator(
                value: film.watchedPercentage,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DisplayTitle(
                          title: film.filmDetails.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                          maxLines:
                              MediaQuery.of(context).size.width > 1024 ? 3 : 2,
                          overflow: TextOverflow.fade,
                          textAlign: TextAlign.center,
                        ),
                        film.filmDetails.isEpisode
                            ? Column(
                                children: [
                                  Text(
                                    (film.filmDetails.seasonEpisodeTag
                                                ?.split(' ')
                                              ?..removeAt(0))
                                            ?.join(' ') ??
                                        '',
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'S${film.parentSeason?.seasonTitle.replaceAll('Sezon ', '')}:O${1 + (film.parentSeason?.episodes.indexWhere((e) => e.episodeUrl == film.filmDetails.url) ?? 0)} z ${film.parentSeason?.episodes.length}',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : Text(
                                'Pozostało: ${film.totalInSec ~/ 60} min',
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                textAlign: TextAlign.center,
                              ),
                      ]),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: film.filmDetails.parentUrl != null
              ? FutureBuilder(
                  future: Provider.of<FilmanNotifier>(context)
                      .getFilmDetails(film.filmDetails.parentUrl!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return const Icon(Icons.error);
                    }

                    return IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => FilmScreen.fromDetails(
                                    details: snapshot.data!,
                                  )),
                        );
                      },
                      icon: const Icon(Icons.info),
                    );
                  })
              : IconButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => FilmScreen.fromDetails(
                            details: film.filmDetails,
                          ))),
                  icon: const Icon(Icons.info)),
        )
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchedNotifier>(
      builder: (context, value, child) {
        List<WatchedSingle> combined =
            value.films + value.serials.map((e) => e.episodes.last).toList();
        combined.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));

        return combined.isEmpty
            ? Center(
                child: Text('Brak filmów w historii oglądania',
                    style: Theme.of(context).textTheme.labelLarge),
              )
            : (GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (MediaQuery.of(context).size.width ~/
                          (MediaQuery.of(context).size.height / 2.5)) +
                      1,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.6,
                ),
                padding: const EdgeInsets.all(10),
                itemCount: combined.length,
                itemBuilder: (BuildContext context, int index) {
                  final film = combined[index];
                  return _buildWatchedFilmCard(context, film, value);
                },
              ));
      },
    );
  }
}