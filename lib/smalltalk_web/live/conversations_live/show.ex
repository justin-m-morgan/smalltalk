# defmodule SmalltalkWeb.ConversationsLive.Show do
#   use SmalltalkWeb, :live_view
#   use LiveStreamAsync

#   alias Smalltalk.Conversations
#   alias Phoenix.LiveView.JS

#   @impl true
#   def mount(params, _session, socket) do
#     dbg(params)
#     actor = socket.assigns.talker
#     conversation_id = Map.fetch!(params, "conversation_id")

#     socket =
#       socket
#       |> assign(actor: actor, conversation_id: conversation_id)
#       |> assign_async(:conversation, fn ->
#         conversation = Conversations.get_conversation!(conversation_id, actor: actor)

#         # for _ <- 1..30 do
#         #   Conversations.send_message!(
#         #     %{conversation: conversation, content: "pspspspspspspspspspsps"},
#         #     actor: actor
#         #   )
#         # end

#         {:ok, %{conversation: conversation}}
#       end)
#       |> stream_configure(:messages, dom_id: &"message-#{&1.id}")
#       |> stream_async(
#         :messages,
#         fn ->
#           Conversations.get_messages_for_conversation!(%{conversation_id: conversation_id},
#             load: [talker: [:profile], read_receipts: [talker: [:profile]]]
#           )
#           |> dbg()
#         end,
#         reset: true
#       )

#     {:ok, socket}
#   end

#   @impl true
#   def render(assigns) do
#     ~H"""
#     <Layouts.app
#       flash={@flash}
#       active_tab={:conversations}
#       active_sub_tab={:show}
#       current_user={@current_user}
#     >
#       <.chat_container>
#         <:header>
#           <.async_result :let={conversation} assign={@conversation}>
#             <:loading></:loading>
#             <:failed></:failed>
#             <.conversation_info_card conversation={conversation} />
#           </.async_result>
#         </:header>
#         <:sidebar>
#           <.chat_sidebar />
#         </:sidebar>
#         <:main>
#           <.async_result :let={stream_key} assign={@messages}>
#             <:loading></:loading>
#             <:failed></:failed>

#             <.chat_messages stream={@streams[stream_key]} actor_id={@actor.id} />
#           </.async_result>
#         </:main>
#         <:bottom>
#           <.chat_input />
#         </:bottom>
#       </.chat_container>
#     </Layouts.app>
#     """
#   end

#   attr :conversation, Conversations.Conversation, required: true

#   defp conversation_info_card(assigns) do
#     ~H"""
#     <Containers.card>
#       <:title>
#         {@conversation.short_name}
#       </:title>

#       <div>
#         {@conversation.description}
#       </div>
#     </Containers.card>
#     """
#   end

#   slot :header
#   slot :sidebar
#   slot :main
#   slot :bottom

#   defp chat_container(assigns) do
#     ~H"""
#     <div
#       style="min-height: 70vh; max-height: calc(100% - 15vh)"
#       class={[
#         "grid grid-cols-[1fr_2fr] grid-rows-[min-content_1fr_min-content] gap-4",
#         "p-4"
#       ]}
#     >
#       <div class="col-span-full bg-base-200 shadow-xl">
#         {render_slot(@header)}
#       </div>
#       <div class="bg-base-200 shadow-xl">{render_slot(@sidebar)}</div>
#       <div class="bg-base-200 shadow-xl">
#         {render_slot(@main)}
#       </div>

#       <div class="bg-base-200 shadow-xl col-span-full">
#         {render_slot(@bottom)}
#       </div>
#     </div>
#     """
#   end

#   defp chat_sidebar(assigns) do
#     ~H"""
#     <aside>
#       <div>chat sidebar</div>
#     </aside>
#     """
#   end

#   attr :stream, Phoenix.LiveView.LiveStream, required: true
#   attr :actor_id, :string, required: true
#   attr :js_event_name, :string, default: "chat_window"

#   defp chat_messages(assigns) do
#     ~H"""
#     <div class="grid relative px-4 py-8">
#       <div class="flex justify-center sticky top-0">
#         <.chat_scroll_button
#           event_name={@js_event_name}
#           messages_container_selector="#messages-stream"
#           icon="hero-arrow-up"
#           direction="top"
#         />
#       </div>
#       <ul
#         id="messages-stream"
#         phx-update="stream"
#         phx-hook="ChatWindow"
#         data-event-name="chat_window"
#         class="grid gap-4 pb-24 max-h-[60vh] overflow-scroll"
#       >
#         <li :for={{id, message} <- @stream} id={id}>
#           <.chat_message message={message} my_id={@actor_id} />
#         </li>
#       </ul>
#       <div class="flex justify-center sticky bottom-0">
#         <.chat_scroll_button
#           event_name={@js_event_name}
#           messages_container_selector="#messages-stream"
#           icon="hero-arrow-down"
#           direction="bottom"
#         />
#       </div>
#     </div>
#     """
#   end

#   attr :event_name, :string, required: true
#   attr :messages_container_selector, :string, required: true
#   attr :icon, :string, values: ["hero-arrow-up", "hero-arrow-down"], required: true
#   attr :direction, :string, values: ["top", "bottom"], required: true

#   defp chat_scroll_button(assigns) do
#     ~H"""
#     <button
#       type="button"
#       class={[
#         "flex justify-center items-center",
#         "rounded-full size-24",
#         "bg-base-100",
#         "opacity-20 hover:opacity-100"
#       ]}
#       phx-click={
#         JS.dispatch(@event_name, to: @messages_container_selector, detail: %{direction: @direction})
#       }
#     >
#       <Icon.icon name={@icon} class="size-16" />
#     </button>
#     """
#   end

#   attr :my_id, :string, required: true
#   attr :message, Conversations.Message, required: true

#   defp chat_message(assigns) do
#     assigns =
#       assign(assigns,
#         receipts: Enum.reject(assigns.message.read_receipts, &(&1.talker_id == assigns.my_id))
#       )

#     ~H"""
#     <div class={[
#       "chat",
#       if(@message.talker_id == @my_id, do: "chat-end")
#     ]}>
#       <div class="chat-header">
#         {@message.talker.profile.first_name}
#         <time class="text-xs opacity-50">12:45</time>
#       </div>
#       <div class={[
#         "chat-bubble",
#         if(@message.talker_id == @my_id,
#           do: "chat-bubble-primary",
#           else: "chat-bubble-accent"
#         )
#       ]}>
#         {@message.content}
#       </div>
#       <div class="chat-footer">
#         <span :if={Enum.any?(@receipts)}>Seen by</span>
#         <span :for={receipt <- @receipts}>
#           {receipt.talker.profile.first_name}
#         </span>
#       </div>
#     </div>
#     """
#   end

#   defp chat_header(assigns) do
#     ~H"""
#     <header>chat header</header>
#     """
#   end

#   defp chat_input(assigns) do
#     ~H"""
#     <div>Inputs</div>
#     """
#   end
# end
