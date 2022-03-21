data "template_file" "task_definition_template" {
    template = file("task-definition.json.tpl")
    vars = {
      REPOSITORY_URL = replace(aws_ecr_repository.php-app.repository_url, "https://", "")
    }
}
