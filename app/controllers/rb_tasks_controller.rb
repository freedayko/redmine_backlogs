include RbCommonHelper

class RbTasksController < RbApplicationController
  unloadable

  def create
    @settings = Backlogs.settings
    @task = nil
    begin
      @task  = RbTask.create_with_relationships(params, User.current.id, @project.id)
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end

    result = @task.errors.size
    status = (result == 0 ? 200 : 400)
    @include_meta = true
    
    new_status_id = Setting.plugin_redmine_backlogs[:story_task_when_new_status_id]
    exclude_status_ids = [ IssueStatus.find_by_is_default(true).id.to_i ]
    in_progress_status_id = Setting.plugin_redmine_backlogs[:story_in_progress_status_id]
    exclude_status_ids.push(in_progress_status_id) unless in_progress_status_id.nil? || in_progress_status_id == 0
    unless new_status_id.nil? || new_status_id.to_i == 0 || !exclude_status_ids.include?(@task.status_id.to_i)
      @task.story.status_id = new_status_id
    end

    respond_to do |format|
      format.html { render :partial => "task", :object => @task, :status => status }
    end
  end

  def update
    @task = RbTask.find_by_id(params[:id])
    @settings = Backlogs.settings
    result = @task.update_with_relationships(params)
    status = (result ? 200 : 400)
    @include_meta = true

    @task.story.story_follow_task_state if @task.story # && Backlogs.Setting[:story_loosely_follows_tasks_states]

    respond_to do |format|
      format.html { render :partial => "task", :object => @task, :status => status }
    end
  end

end
