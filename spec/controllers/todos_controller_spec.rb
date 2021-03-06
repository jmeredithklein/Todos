require 'rails_helper'

RSpec.describe TodosController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }

  before(:each) { login_user user }

  shared_examples_for 'not found' do
    context 'when todo does not exist with given id' do
      let(:do_request) { subject }
      let(:todo_id) { -1 }

      it 'should raise ActiveRecord::RecordNotFound' do
        expect { do_request }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'GET #index' do
    subject(:do_get) { get :index }

    let!(:todo) { FactoryGirl.create(:todo, user: user) }
    let!(:other_todo) { FactoryGirl.create(:todo) }

    it 'should assign @todos that belong to user' do
      do_get
      expect(assigns(:todos)).to include todo
    end

    it 'should not include other todos' do
      do_get
      expect(assigns(:todos)).to_not include other_todo
    end
  end

  describe 'GET #new' do
    subject(:do_get) { get :new }

    it 'should assign @todo' do
      do_get
      expect(assigns(:todo)).to be_an_instance_of Todo
    end
  end

  describe 'GET #edit' do
    subject(:do_get) { get :edit, id: todo_id }

    let(:todo) { FactoryGirl.create(:todo, user: user) }
    let(:todo_id) { todo.id }

    it 'should assign @todo' do
      do_get
      expect(assigns(:todo)).to eq todo
    end

    context 'when editing another user\'s Todo' do
      let(:todo) { FactoryGirl.create(:todo) }

      include_examples 'not found'
    end

    include_examples 'not found'
  end

  describe 'POST #create' do
    subject(:do_post) { post :create, todo: params }

    let(:params) { FactoryGirl.attributes_for(:todo) }
    let(:new_todo) { Todo.last }

    it 'should create a Todo' do
      expect { do_post }.to change { Todo.count }.by(1)
    end

    it 'should create a Todo with given params' do
      do_post
      expect(new_todo).to have_attributes params
    end

    it 'should create a Todo associated with User' do
      do_post
      expect(user.todos).to include new_todo
    end

    it 'should redirect to todos index' do
      do_post
      expect(response).to redirect_to todos_path
    end

    context 'with invalid params' do
      let(:params) { { title: nil } }

      it 'should not create a Todo' do
        expect { do_post }.to_not change { Todo.count }
      end

      it 'should render :new' do
        do_post
        expect(response).to render_template :new
      end
    end
  end

  describe 'PUT #update' do
    subject(:do_put) { put :update, id: todo_id, todo: params }

    let(:todo) { FactoryGirl.create(:todo, user: user) }
    let(:todo_id) { todo.id }
    let(:params) { FactoryGirl.attributes_for(:todo) }

    it 'should update existing Todo' do
      expect { do_put }.to change { todo.reload.attributes }
    end

    it 'should update existing Todo with given params' do
      do_put
      expect(todo.reload).to have_attributes params
    end

    it 'should redirect to todos index' do
      do_put
      expect(response).to redirect_to todos_path
    end

    context 'when updating another user\'s Todo' do
      let(:todo) { FactoryGirl.create(:todo) }

      it 'should not update existing' do
        expect { do_put rescue nil }.to_not change { todo.reload.attributes }
      end

      include_examples 'not found'
    end

    include_examples 'not found'
  end

  describe 'DELETE #destroy' do
    subject(:do_delete) { delete :destroy, id: todo_id }

    let!(:todo) { FactoryGirl.create(:todo, user: user) }
    let(:todo_id) { todo.id }

    it 'should delete a Todo' do
      expect { do_delete }.to change { Todo.count }.by(-1)
    end

    it 'should delete Todo with given id' do
      expect { do_delete }.to change { Todo.exists?(todo) }.to(false)
    end

    context 'when deleting another user\'s Todo' do
      let(:todo) { FactoryGirl.create(:todo) }

      it 'should not delete existing' do
        expect { do_delete rescue nil }.to_not change { Todo.count }
      end

      include_examples 'not found'
    end

    include_examples 'not found'
  end

  describe 'PUT #completed' do
    subject(:do_put) { put :completed, id: todo_id }

    let!(:todo) { FactoryGirl.create(:todo, user: user) }
    let(:todo_id) { todo.id }

    it 'should mark todo as complete' do
      expect { do_put }.to change { todo.reload.complete }.to(true)
    end

    context 'when marking complete another user\'s Todo' do
      let(:todo) { FactoryGirl.create(:todo) }

      it 'should not mark complete' do
        expect { do_put rescue nil }.to_not change { todo.reload.complete }
      end

      include_examples 'not found'
    end
  end

  describe 'DELETE #delete_all' do
    subject(:do_delete) { delete :delete_all }

    let!(:todo) { FactoryGirl.create(:todo, user: user) }

    it 'should delete all Todos that belong to user' do
      expect { do_delete }.to change { Todo.count }.to(0)
    end

    context 'when other todos exist' do
      let!(:todo) { FactoryGirl.create(:todo) }

      it 'should not delete other user\'s todos' do
        expect { do_delete rescue nil }.to_not change { Todo.count }
      end
    end
  end
end
