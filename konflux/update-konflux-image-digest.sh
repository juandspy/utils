#! /bin/bash

konflux_path="${PWD}/.tekton"
if [[ -d "${konflux_path}" ]]; then
  for konflux_file in "${konflux_path}"/*.yaml; do
    sast_tasks=$(yq '.spec.pipelineSpec.tasks[] | select(.name == "sast-*").name' ${konflux_file})
    for task in ${sast_tasks}; do
      has_digest=$(yq '.spec.pipelineSpec.tasks[] | select(.name == "'${task}'").params | any_c(.name == "image-digest")' ${konflux_file})
      url_value=$(yq '.spec.pipelineSpec.tasks[] | select(.name == "'${task}'").params[] | select(.name == "image-url").value' ${konflux_file})
      if [[ "${url_value}" == "null" ]]; then
        url_value='$(tasks.build-image-index.results.IMAGE_DIGEST)'
      fi
      if [[ ${has_digest} == false ]]; then
        yq '.spec.pipelineSpec.tasks[] |= select(.name == "'${task}'").params |= [{"name":"image-digest","value":"'${url_value//URL/DIGEST}'"}] + .' -i ${konflux_file}
      else
        yq '.spec.pipelineSpec.tasks[] |= select(.name == "'${task}'").params[] |= select(.name == "image-digest").value = "'${url_value//URL/DIGEST}'"' -i ${konflux_file}
      fi
    done
  done
fi