ActiveAdmin.register Flag do
  config.filters = false

  actions :all, except: %i[destroy new edit]

  menu priority: 2
  config.batch_actions = false

  permit_params :status, :taken_action

  scope :active, default: true
  scope :resolved

  member_action :ban_flagged_user, method: :post
  member_action :dismiss, method: :post
  member_action :remove_project_submission, method: :post

  index do
    selectable_column
    id_column

    column :reason
    column :status
    column :taken_action
  end

  show do |flag|
    attributes_table do
      row :flagger
      row :reason
      row :submission_ower do
        flag.project_submission.user.username
      end
      row :repo_url do
        link_to flag.project_submission.repo_url, flag.project_submission.repo_url, target: '_blank'
      end
      row :live_preview_url do
        link_to flag.project_submission.live_preview_url, flag.project_submission.live_preview_url, target: '_blank'
      end
      row :status
      row :taken_action
      row :created_at
      row :number_of_times_flagger_has_had_a_dismissed_flag do
        flag.flagger.dismissed_flags.size
      end
      row :project_submission_flag_count do
        flags = Flag.where(project_submission: flag.project_submission)
        active = flags.count { |r| r.status == 'active' }
        resolved = flags.count { |r| r.status == 'resolved' }
        "#{flags.count} (#{active} active, #{resolved} resolved)"
      end

      render 'flag_actions', flag: flag
    end
  end

  controller do
    def ban_flagged_user
      result = Admin::Flags::BanUser.call(flag: resource)

      if result.success?
        redirect_to resource_path(resource), notice: 'Success: User has been banned.'
      else
        redirect_to resource_path(resource), notice: 'Failure: Unable to ban user, please check logs.'
      end
    end

    def dismiss
      result = Admin::Flags::Dismiss.call(flag: resource)

      if result.success?
        redirect_to resource_path(resource), notice: 'Success: Flag has been dismissed.'
      else
        redirect_to resource_path(resource), notice: 'Failure: Unable to dismiss flag, please check logs.'
      end
    end

    def remove_project_submission
      resource.project_submission.destroy

      redirect_to admin_flags_path, notice: 'Success: Submission has been removed.'
    end
  end
end
