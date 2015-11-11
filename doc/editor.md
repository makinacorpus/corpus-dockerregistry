# Notes about the editor group

When a container is running

- editor members can edit files
- some files served by app workers & webservers must be readonly by the processes
  inside the container
- files can be edited by a non root user from the outside of the container

