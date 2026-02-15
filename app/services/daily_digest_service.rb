class DailyDigestService
  def initialize(user, date: nil)
    @user = user
    @date = date || Time.current.to_date
  end

  def call
    {
      date: @date.iso8601,
      todos: {
        today: todays_todos,
        overdue: overdue_todos,
        tomorrow: tomorrows_todos,
        this_week: this_weeks_todos
      },
      events: {
        today: todays_events,
        this_week: this_weeks_events
      },
      summary: summary
    }
  end

  private

  def todays_todos
    @user.todos
      .includes(milestone: :project)
      .where(completed_at: nil, priority_window: "today")
      .order(:position)
      .map { |todo| format_todo(todo) }
  end

  def overdue_todos
    @user.todos
      .includes(milestone: :project)
      .where(completed_at: nil)
      .where.not(priority_window: [ "today", "tomorrow", "this_week", "next_week" ])
      .order(created_at: :desc)
      .map { |todo| format_todo(todo) }
  end

  def tomorrows_todos
    @user.todos
      .includes(milestone: :project)
      .where(completed_at: nil, priority_window: "tomorrow")
      .order(:position)
      .map { |todo| format_todo(todo) }
  end

  def this_weeks_todos
    @user.todos
      .includes(milestone: :project)
      .where(completed_at: nil, priority_window: "this_week")
      .order(:position)
      .map { |todo| format_todo(todo) }
  end

  def todays_events
    @user.events
      .left_joins(:project)
      .where("projects.archived_at IS NULL OR events.project_id IS NULL")
      .includes(:project)
      .for_date_range(@date, @date)
      .map { |event| format_event(event) }
  end

  def this_weeks_events
    week_end = @date.end_of_week
    @user.events
      .left_joins(:project)
      .where("projects.archived_at IS NULL OR events.project_id IS NULL")
      .includes(:project)
      .for_date_range(@date, week_end)
      .map { |event| format_event(event) }
  end

  def summary
    {
      todos_count: @user.todos.where(completed_at: nil, priority_window: "today").count,
      overdue_count: @user.todos
        .where(completed_at: nil)
        .where.not(priority_window: [ "today", "tomorrow", "this_week", "next_week" ])
        .count,
      events_today: @user.events.for_date_range(@date, @date).count,
      events_this_week: @user.events
        .for_date_range(@date, @date.end_of_week)
        .count
    }
  end

  def format_todo(todo)
    {
      id: todo.id,
      title: todo.title,
      priority_window: todo.priority_window,
      position: todo.position,
      created_at: todo.created_at.iso8601,
      milestone: format_milestone(todo.milestone),
      project: format_project(todo.milestone&.project)
    }
  end

  def format_event(event)
    {
      id: event.id,
      title: event.title,
      description: event.description,
      starts_at: event.starts_at.iso8601,
      ends_at: event.ends_at.iso8601,
      all_day: event.all_day,
      event_type: event.event_type,
      project: format_project(event.project)
    }
  end

  def format_milestone(milestone)
    return nil unless milestone

    {
      id: milestone.id,
      name: milestone.name
    }
  end

  def format_project(project)
    return nil unless project

    {
      id: project.id,
      name: project.name
    }
  end
end
