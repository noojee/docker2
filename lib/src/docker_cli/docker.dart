import 'package:dcli/dcli.dart';

import 'container.dart';
import 'containers.dart';
import 'exceptions.dart';
import 'image.dart';
import 'image_name.dart';
import 'images.dart';

/// Top level class generally used as the starting point manage
/// docker containers and images.
class Docker {
  /// Searches for and returns the image that matches
  /// [imageName].
  /// If more than one image matches then an [AmbiguousImageNameException]
  /// is thrown.
  /// If no matching image is found a null is returned.
  ///
  /// The fullName is of the form registry/repo/name:tag
  /// The registry, repo and tag are optional.
  ///
  /// e.g.
  /// dockerhub.io/canonical/ubuntu:latest
  /// canonical/ubuntu
  /// ubuntu
  /// ubuntu:latest
  Image? findImageByName(String imageName) {
    ImageName.fromName(imageName);
    return Images().findByName(imageName);
  }

  /// Returns an [Image] for the give [imageId].
  /// If the [imageId] is not found then null is returned.
  Image? findImageById(String imageId) => Images().findByImageId(imageId);

  /// Searches for a container with the given [containerId].
  /// Returns null if a container could not be found.
  Container? findContainerById(String containerId) =>
      Containers().findByContainerId(containerId);

  /// Searches for a container with the given [containerName].
  /// Returns null if a container could not be found.
  Container? findContainerByName(String containerName) =>
      Containers().findByName(containerName);

  /// Pulls an image from a remote repository.
  /// The fullName is of the form repo/name:tag
  /// The repo and tag are optional.
  ///
  /// e.g.
  /// dockerhub.io/ubuntu:latest
  /// ubuntu
  /// ubuntu:latest
  Image pull(String fullname) {
    final _imageName = ImageName.fromName(fullname);

    Image? image = Image.fromName(_imageName.fullname)..pull();
    image = Images().findByName(_imageName.fullname);
    if (image == null) {
      throw ImageNotFoundException(fullname);
    }
    return image;
  }

  /// creates a container from the passed [image] with
  /// the given [containerName].
  /// The [args] and [argString] are appended to the command
  /// and allow you to add abitrary arguments.
  /// The [args] list is added before the [argString].
  Container create(Image image, String containerName,
          {List<String>? args, String? argString}) =>
      image.create(containerName, args: args, argString: argString);

  /// Returns a list of containers
  /// If [excludeStopped] is true (defaults to false) then
  /// only running containers will be returned.
  List<Container> containers({bool excludeStopped = false}) =>
      Containers().containers(excludeStopped: excludeStopped);

  /// internal function to provide a consistent method of handling
  /// failed execution of the docker command.
  List<String> _dockerRun(String cmd, String args) {
    final progress =
        'docker $cmd $args'.start(nothrow: true, progress: Progress.capture());

    if (progress.exitCode != 0) {
      throw DockerCommandFailed(
          cmd, args, progress.exitCode!, progress.lines.join('\n'));
    }
    return progress.lines;
  }
}

/// runs the passed docker command.
List<String> dockerRun(String cmd, String args) =>
    Docker()._dockerRun(cmd, args);